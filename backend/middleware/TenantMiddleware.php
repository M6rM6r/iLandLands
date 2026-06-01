<?php

declare(strict_types=1);

/**
 * TenantMiddleware for the primary vanilla PHP REST API.
 *
 * Resolves the current tenant from the JWT payload attached by JwtAuthMiddleware.
 * Validates the tenant exists and is active, then stores the tenant record in
 * $_REQUEST['_tenant'] for downstream controllers.
 *
 * Usage — call once after JwtAuthMiddleware::handle():
 *
 *   JwtAuthMiddleware::handle();
 *   TenantMiddleware::handle($pdo);
 *
 * Controllers access context via:
 *   $tenantId = $_REQUEST['_tenant']['id'];
 */
class TenantMiddleware
{
    /**
     * Paths that do NOT require a tenant context (public read-only routes).
     * Must match the same allow-list used in JwtAuthMiddleware.
     */
    private static array $publicPrefixes = [
        '/api/v1/auth/',
        '/api/v1/health',
    ];

    public static function handle(PDO $pdo): void
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $path   = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '';

        // Skip OPTIONS preflight
        if ($method === 'OPTIONS') {
            return;
        }

        // Skip fully public routes
        foreach (self::$publicPrefixes as $prefix) {
            if (str_starts_with($path, $prefix)) {
                return;
            }
        }

        // Auth middleware must have run first
        $authUser = $_REQUEST['_auth_user'] ?? null;
        if ($authUser === null) {
            // Public GET listing routes have no _auth_user — skip tenant enforcement
            // (tenant is not required to browse public listings)
            if ($method === 'GET') {
                return;
            }
            self::respond(401, 'Authentication required before tenant resolution');
        }

        $tenantId = $authUser['tenant_id'] ?? null;

        if (empty($tenantId)) {
            self::respond(400, 'JWT is missing required claim: tenant_id');
        }

        // Validate UUID format (defence-in-depth before hitting the DB)
        if (!preg_match(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i',
            (string) $tenantId
        )) {
            self::respond(400, 'Invalid tenant_id format in JWT');
        }

        $stmt = $pdo->prepare(
            'SELECT id, name, slug, plan, status, settings FROM tenants WHERE id = ? LIMIT 1'
        );
        $stmt->execute([$tenantId]);
        $tenant = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($tenant === false) {
            self::respond(404, 'Tenant not found');
        }

        if ($tenant['status'] !== 'active') {
            self::respond(403, 'Tenant account is suspended or deleted');
        }

        // Decode JSON settings column
        if (!empty($tenant['settings']) && is_string($tenant['settings'])) {
            $tenant['settings'] = json_decode($tenant['settings'], true) ?? [];
        }

        $_REQUEST['_tenant']    = $tenant;
        $_REQUEST['_tenant_id'] = $tenantId;
    }

    /** Terminate with a JSON error response. */
    private static function respond(int $status, string $message): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode([
            'error'   => self::statusLabel($status),
            'message' => $message,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    private static function statusLabel(int $status): string
    {
        return match ($status) {
            400     => 'Bad Request',
            401     => 'Unauthorized',
            403     => 'Forbidden',
            404     => 'Not Found',
            default => 'Error',
        };
    }
}
