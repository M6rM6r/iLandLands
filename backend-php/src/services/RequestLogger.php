<?php

namespace App\Services;

/**
 * RequestLogger — structured JSON request logging for Slim 4.
 *
 * Ported from Rew (realestate-saas) lib/observability.ts.
 *
 * Emits one JSON line per event to error_log() (captured by Docker/syslog).
 * Sensitive keys are automatically redacted — never logs credentials.
 *
 * Usage (in a Slim 4 route handler or middleware):
 *   $t0 = microtime(true);
 *   RequestLogger::logInfo('listings.index', 'Listings fetched', ['count' => 15]);
 *   RequestLogger::logDuration('listings.index', $t0, ['status' => 200]);
 *
 *   RequestLogger::logError('listings.create', $e, ['tenant_id' => $tenantId]);
 */
class RequestLogger
{
    private const REDACT_KEYS = [
        'password', 'token', 'authorization', 'cookie', 'set-cookie',
        'secret', 'privatekey', 'apikey', 'api_key', 'auth_key',
        'telr_auth_key', 'openai_api_key', 'hubspot_access_token',
        'whatsapp_token',
    ];

    public static function logInfo(string $route, string $message, array $context = []): void
    {
        self::emit('info', $route, $message, $context);
    }

    public static function logError(string $route, \Throwable $error, array $context = []): void
    {
        self::emit('error', $route, $error->getMessage(), array_merge($context, [
            'error_class'   => get_class($error),
            'error_message' => $error->getMessage(),
        ]));
    }

    /**
     * @param float $startTime  microtime(true) captured at request entry.
     */
    public static function logDuration(string $route, float $startTime, array $context = []): void
    {
        $ms = (int) round((microtime(true) - $startTime) * 1000);
        self::emit('info', $route, 'Route complete', array_merge($context, [
            'duration_ms'    => $ms,
            'latency_bucket' => self::latencyBucket($ms),
        ]));
    }

    private static function emit(string $level, string $route, string $message, array $context): void
    {
        if (!FeatureFlags::isEnabled('ADVANCED_OBSERVABILITY')) {
            return;
        }

        $entry = array_merge(
            [
                'level'      => $level,
                'timestamp'  => gmdate('c'),
                'route'      => $route,
                'message'    => $message,
                'request_id' => self::requestId(),
                'method'     => $_SERVER['REQUEST_METHOD'] ?? 'CLI',
                'path'       => $_SERVER['REQUEST_URI']    ?? '',
            ],
            self::sanitize($context)
        );

        error_log(json_encode($entry, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    }

    private static function sanitize(array $data): array
    {
        $out = [];
        foreach ($data as $key => $value) {
            if (in_array(strtolower((string) $key), self::REDACT_KEYS, true)) {
                $out[$key] = '[REDACTED]';
            } elseif (is_array($value)) {
                $out[$key] = self::sanitize($value);
            } else {
                $out[$key] = $value;
            }
        }
        return $out;
    }

    private static function latencyBucket(int $ms): string
    {
        if ($ms < 100)  return 'lt_100ms';
        if ($ms < 300)  return 'lt_300ms';
        if ($ms < 1000) return 'lt_1s';
        if ($ms < 3000) return 'lt_3s';
        return 'gte_3s';
    }

    private static function requestId(): string
    {
        static $id = null;
        if ($id === null) {
            $id = $_SERVER['HTTP_X_REQUEST_ID'] ?? bin2hex(random_bytes(8));
        }
        return $id;
    }
}
