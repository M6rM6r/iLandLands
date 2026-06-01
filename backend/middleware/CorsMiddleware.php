<?php

class CorsMiddleware {
    public static function handle() {
        // Allowed origins come from environment so they can differ per deployment.
        // Never fall back to wildcard (*) — that bypasses same-origin protection.
        $envOrigins = getenv('CORS_ORIGINS');
        $allowedOrigins = $envOrigins
            ? array_map('trim', explode(',', $envOrigins))
            : [
                'https://gulflands.com',
                'https://www.gulflands.com',
                'https://api.gulflands.com',
            ];

        // Development convenience: allow localhost variants only when ENVIRONMENT is not production
        if (getenv('ENVIRONMENT') !== 'production') {
            $allowedOrigins = array_merge($allowedOrigins, [
                'http://localhost:3000',
                'http://localhost:8080',
            ]);
        }

        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

        if ($origin !== '' && in_array($origin, $allowedOrigins, true)) {
            header("Access-Control-Allow-Origin: $origin");
            header("Vary: Origin");
        }
        // If origin is not in whitelist: no ACAO header is emitted.
        // The browser will block the request — this is the correct secure behaviour.

        header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
        header("Access-Control-Allow-Credentials: true");
        header("Access-Control-Max-Age: 86400");
        header("Access-Control-Expose-Headers: X-Total-Count, X-Page-Count");
    }
}

