<?php

namespace App\Services;

/**
 * RateLimiter — Redis sliding-window rate limiter (Slim 4 / PSR namespace).
 *
 * @see backend/services/RateLimiter.php for the vanilla-PHP counterpart.
 *
 * Environment variables required:
 *   REDIS_HOST     — default 127.0.0.1
 *   REDIS_PORT     — default 6379
 *   REDIS_PASSWORD — optional
 */
class RateLimiter
{
    private const KEY_PREFIX    = 'rl:';
    private const DEFAULT_LIMIT = 20;
    private const DEFAULT_TTL   = 60;

    /** @var \Redis|null */
    private static ?\Redis $redis = null;
    private static bool $unavailable = false;

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Returns TRUE if the request is within limits, FALSE if blocked.
     */
    public static function isAllowed(
        string $identifier,
        int    $limit      = self::DEFAULT_LIMIT,
        int    $windowSecs = self::DEFAULT_TTL
    ): bool {
        if (self::$unavailable) {
            return true;
        }

        try {
            $redis = self::connection();
            if ($redis === null) {
                return true;
            }

            $key     = self::KEY_PREFIX . $identifier;
            $current = $redis->incr($key);

            if ($current === 1) {
                $redis->expire($key, $windowSecs);
            }

            return $current <= $limit;
        } catch (\Throwable $e) {
            error_log('[RateLimiter] Redis error: ' . $e->getMessage());
            self::$unavailable = true;
            return true;
        }
    }

    /**
     * Derive a hashed IP identifier from the PSR-7 request.
     *
     * @param \Psr\Http\Message\ServerRequestInterface $request
     */
    public static function ipIdentifier(\Psr\Http\Message\ServerRequestInterface $request): string
    {
        $xff = $request->getHeaderLine('X-Forwarded-For');
        $ip  = trim(explode(',', $xff)[0]);
        if ($ip === '') {
            $serverParams = $request->getServerParams();
            $ip           = (string) ($serverParams['REMOTE_ADDR'] ?? '127.0.0.1');
        }
        return 'ip:' . hash('sha256', $ip);
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    private static function connection(): ?\Redis
    {
        if (self::$redis !== null) {
            return self::$redis;
        }

        if (!class_exists('\\Redis')) {
            error_log('[RateLimiter] PHP Redis extension not installed');
            self::$unavailable = true;
            return null;
        }

        $host     = (string) (getenv('REDIS_HOST')     ?: '127.0.0.1');
        $port     = (int)    (getenv('REDIS_PORT')     ?: 6379);
        $password = (string) (getenv('REDIS_PASSWORD') ?: '');

        $r = new \Redis();
        $r->connect($host, $port, 1.5);
        if ($password !== '') {
            $r->auth($password);
        }

        self::$redis = $r;
        return self::$redis;
    }
}
