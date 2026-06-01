<?php

/**
 * RateLimiter — Redis sliding-window rate limiter.
 *
 * Ported from Rew/lib/rate-limit.ts (Upstash Redis → native Redis via Predis).
 * Uses a fixed-window counter stored in Redis with TTL. Falls back to allow-all
 * when Redis is unavailable (graceful degradation, never blocks traffic due to
 * infrastructure failure).
 *
 * Environment variables required:
 *   REDIS_HOST     — default 127.0.0.1
 *   REDIS_PORT     — default 6379
 *   REDIS_PASSWORD — optional
 *
 * @see backend-php/src/services/RateLimiter.php for the Slim 4 counterpart.
 */
class RateLimiter
{
    private const KEY_PREFIX    = 'rl:';
    private const DEFAULT_LIMIT = 20;          // max requests
    private const DEFAULT_TTL   = 60;          // window in seconds

    /** @var Redis|null */
    private static ?Redis $redis = null;
    private static bool $unavailable = false;

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Check whether the given identifier has exceeded the rate limit.
     *
     * @param  string $identifier   IP address, user ID, or any string key
     * @param  int    $limit        Max allowed requests per window
     * @param  int    $windowSecs   Window duration in seconds
     * @return bool                 TRUE if the request is allowed, FALSE if blocked
     */
    public static function isAllowed(
        string $identifier,
        int    $limit      = self::DEFAULT_LIMIT,
        int    $windowSecs = self::DEFAULT_TTL
    ): bool {
        if (self::$unavailable) {
            return true; // fail open
        }

        try {
            $redis = self::connection();
            if ($redis === null) {
                return true; // fail open
            }

            $key     = self::KEY_PREFIX . $identifier;
            $current = $redis->incr($key);

            // Set TTL only on first request in the window
            if ($current === 1) {
                $redis->expire($key, $windowSecs);
            }

            return $current <= $limit;
        } catch (Throwable $e) {
            error_log('[RateLimiter] Redis error: ' . $e->getMessage());
            self::$unavailable = true;
            return true; // fail open
        }
    }

    /**
     * Send a 429 JSON response and terminate execution if rate limit is exceeded.
     *
     * @param  string $identifier
     * @param  int    $limit
     * @param  int    $windowSecs
     */
    public static function throttle(
        string $identifier,
        int    $limit      = self::DEFAULT_LIMIT,
        int    $windowSecs = self::DEFAULT_TTL
    ): void {
        if (!self::isAllowed($identifier, $limit, $windowSecs)) {
            http_response_code(429);
            header('Content-Type: application/json');
            header('Retry-After: ' . $windowSecs);
            echo json_encode(['error' => 'Too many requests. Please try again later.']);
            exit;
        }
    }

    /**
     * Derive a stable, anonymised identifier from the current HTTP request.
     * Prefers X-Forwarded-For (set by trusted reverse proxy), falls back to REMOTE_ADDR.
     *
     * The identifier is hashed so raw IPs are never stored in Redis.
     */
    public static function ipIdentifier(): string
    {
        $xff  = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? '';
        $ip   = trim(explode(',', $xff)[0]) ?: ($_SERVER['REMOTE_ADDR'] ?? '127.0.0.1');
        return 'ip:' . hash('sha256', $ip);
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    private static function connection(): ?Redis
    {
        if (self::$redis !== null) {
            return self::$redis;
        }

        if (!class_exists('Redis')) {
            error_log('[RateLimiter] PHP Redis extension not installed');
            self::$unavailable = true;
            return null;
        }

        $host     = (string) (getenv('REDIS_HOST')     ?: '127.0.0.1');
        $port     = (int)    (getenv('REDIS_PORT')     ?: 6379);
        $password = (string) (getenv('REDIS_PASSWORD') ?: '');

        $r = new Redis();
        $r->connect($host, $port, 1.5); // 1.5 s connect timeout
        if ($password !== '') {
            $r->auth($password);
        }
        $r->setOption(Redis::OPT_PREFIX, '');

        self::$redis = $r;
        return self::$redis;
    }
}
