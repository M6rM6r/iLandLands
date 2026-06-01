<?php

/**
 * JWT Authentication Middleware for primary PHP REST API.
 *
 * Validates Bearer tokens on protected routes.
 * Safe-lists read-only GET requests and the /auth/ prefix.
 */
class JwtAuthMiddleware {

    /** Routes that never require authentication (exact prefix match). */
    private static array $publicPrefixes = [
        '/api/v1/auth/',
        '/api/v1/health',
        '/api/v1/land-listings',   // read-only GET allowed publicly
        '/api/v1/search',
    ];

    /** HTTP methods that always require authentication regardless of route. */
    private static array $writeMethodsRequiringAuth = ['POST', 'PUT', 'PATCH', 'DELETE'];

    public static function handle(): void {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $path   = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '';

        // Allow OPTIONS preflight without auth
        if ($method === 'OPTIONS') {
            return;
        }

        // Allow public GET prefixes
        if ($method === 'GET') {
            foreach (self::$publicPrefixes as $prefix) {
                if (str_starts_with($path, $prefix)) {
                    return;
                }
            }
        }

        // All write operations and non-public GET paths require a valid token
        if (in_array($method, self::$writeMethodsRequiringAuth, true) || $method === 'GET') {
            $decoded = self::validateToken();
            // Attach decoded payload to a superglobal so controllers can access it
            $_REQUEST['_auth_user'] = (array) $decoded;
        }
    }

    /**
     * Validates the Bearer token and returns the decoded payload.
     * Terminates with 401 on any failure.
     */
    public static function validateToken(): object {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
            self::unauthorized('Missing or malformed Authorization header');
        }

        $secret = getenv('JWT_SECRET');
        if (!$secret) {
            error_log('FATAL: JWT_SECRET environment variable is not set');
            http_response_code(500);
            echo json_encode(['error' => 'Server configuration error']);
            exit;
        }

        $token = $matches[1];
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            self::unauthorized('Invalid token format');
        }

        [$headerB64, $payloadB64, $signatureB64] = $parts;

        // Verify signature using constant-time comparison to prevent timing attacks
        $expectedSig = self::base64UrlEncode(hash_hmac('sha256', "$headerB64.$payloadB64", $secret, true));
        if (!hash_equals($expectedSig, $signatureB64)) {
            self::unauthorized('Invalid token signature');
        }

        $payload = json_decode(self::base64UrlDecode($payloadB64));
        if (!$payload) {
            self::unauthorized('Malformed token payload');
        }

        // Check expiry
        if (isset($payload->exp) && $payload->exp < time()) {
            self::unauthorized('Token expired');
        }

        // Check issued-at is not in the future (clock skew tolerance: 60s)
        if (isset($payload->iat) && $payload->iat > time() + 60) {
            self::unauthorized('Token issued in the future');
        }

        return $payload;
    }

    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    private static function unauthorized(string $message): never {
        http_response_code(401);
        header('Content-Type: application/json');
        echo json_encode(['error' => 'Unauthorized', 'message' => $message]);
        exit;
    }
}
