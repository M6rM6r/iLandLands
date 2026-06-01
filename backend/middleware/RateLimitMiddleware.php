<?php

class RateLimitMiddleware {
    private static $redis = null;
    private static $limits = [
        'default' => ['requests' => 100, 'window' => 3600], // 100 requests per hour
        'search' => ['requests' => 30, 'window' => 3600],    // 30 searches per hour
        'analytics' => ['requests' => 1000, 'window' => 3600] // 1000 analytics events per hour
    ];

    public static function handle($endpoint = 'default') {
        $ipAddress = self::getClientIp();
        $limit = self::$limits[$endpoint] ?? self::$limits['default'];
        
        // Try Redis first, fallback to file-based limiting
        if (self::isRedisAvailable()) {
            return self::handleRedisLimit($ipAddress, $limit);
        } else {
            return self::handleFileLimit($ipAddress, $limit);
        }
    }

    private static function getClientIp() {
        // SECURITY: Only trust forwarded-for headers when the direct peer is a known
        // trusted proxy (Docker internal network 172.20.0.0/16 and loopback).
        // Never blindly trust client-supplied headers — they are trivially spoofed.
        $trustedProxyCidrs = ['172.20.0.0/16', '127.0.0.1/32', '::1/128'];
        $remoteAddr = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';

        if (self::isIpInCidrs($remoteAddr, $trustedProxyCidrs)) {
            // Peer is a trusted proxy; read the last value from X-Forwarded-For.
            // We read the LAST (rightmost) address written by our own trusted proxy,
            // not the first, to prevent injection by malicious clients.
            $xForwardedFor = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? '';
            if ($xForwardedFor !== '') {
                $ips = array_map('trim', explode(',', $xForwardedFor));
                $clientIp = end($ips); // rightmost = appended by our proxy
                if (filter_var($clientIp, FILTER_VALIDATE_IP)) {
                    return $clientIp;
                }
            }

            $xRealIp = $_SERVER['HTTP_X_REAL_IP'] ?? '';
            if ($xRealIp !== '' && filter_var($xRealIp, FILTER_VALIDATE_IP)) {
                return $xRealIp;
            }
        }

        return $remoteAddr;
    }

    private static function isIpInCidrs(string $ip, array $cidrs): bool {
        $ipLong = ip2long($ip);
        if ($ipLong === false) {
            return false;
        }
        foreach ($cidrs as $cidr) {
            [$subnet, $bits] = explode('/', $cidr);
            $subnetLong = ip2long($subnet);
            if ($subnetLong === false) {
                continue;
            }
            $mask = -1 << (32 - (int)$bits);
            if (($ipLong & $mask) === ($subnetLong & $mask)) {
                return true;
            }
        }
        return false;
    }

    private static function isRedisAvailable() {
        if (self::$redis !== null) {
            return true;
        }

        try {
            self::$redis = new Redis();
            self::$redis->connect('127.0.0.1', 6379, 1);
            self::$redis->setOption(Redis::OPT_SERIALIZER, Redis::SERIALIZER_NONE);
            return true;
        } catch (Exception $e) {
            self::$redis = null;
            return false;
        }
    }

    private static function handleRedisLimit($ipAddress, $limit) {
        $key = "rate_limit:{$ipAddress}";
        $current = self::$redis->get($key);
        
        if ($current === false) {
            // First request in window
            self::$redis->setex($key, $limit['window'], 1);
            return true;
        }

        if ($current >= $limit['requests']) {
            self::sendRateLimitResponse($limit);
            return false;
        }

        self::$redis->incr($key);
        return true;
    }

    private static function handleFileLimit($ipAddress, $limit) {
        $cacheDir = __DIR__ . '/../cache/rate_limits/';
        if (!is_dir($cacheDir)) {
            mkdir($cacheDir, 0755, true);
        }

        $file = $cacheDir . md5($ipAddress) . '.json';
        $now = time();
        $windowStart = $now - $limit['window'];

        $data = [];
        if (file_exists($file)) {
            $data = json_decode(file_get_contents($file), true) ?: [];
        }

        // Clean old requests
        $data = array_filter($data, function($timestamp) use ($windowStart) {
            return $timestamp > $windowStart;
        });

        if (count($data) >= $limit['requests']) {
            self::sendRateLimitResponse($limit);
            return false;
        }

        // Add current request
        $data[] = $now;
        file_put_contents($file, json_encode($data));
        return true;
    }

    private static function sendRateLimitResponse($limit) {
        http_response_code(429);
        header('Content-Type: application/json');
        header('Retry-After: ' . $limit['window']);
        
        echo json_encode([
            'error' => 'Rate limit exceeded',
            'message' => 'Too many requests. Please try again later.',
            'limit' => $limit['requests'],
            'window' => $limit['window']
        ]);
        exit();
    }

    public static function cleanup() {
        // Clean up old rate limit files (run via cron)
        $cacheDir = __DIR__ . '/../cache/rate_limits/';
        if (!is_dir($cacheDir)) {
            return;
        }

        $files = glob($cacheDir . '*.json');
        $cutoff = time() - 3600; // Remove files older than 1 hour

        foreach ($files as $file) {
            if (filemtime($file) < $cutoff) {
                unlink($file);
            }
        }
    }
}
?>
