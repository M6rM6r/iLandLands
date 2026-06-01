<?php

declare(strict_types=1);

namespace App\Middleware;

use PDO;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;

/**
 * TenantMiddleware
 *
 * Resolves the current tenant from the JWT claim `tenant_id` set by AuthMiddleware.
 * Validates the tenant is active, then attaches the full tenant record to the
 * request attribute 'tenant' for downstream handlers.
 *
 * Must be added AFTER AuthMiddleware on any route that needs tenant context.
 *
 * Request flow:
 *   AuthMiddleware → TenantMiddleware → Handler
 *
 * The resolved tenant array is available in handlers via:
 *   $tenant = $request->getAttribute('tenant');
 */
class TenantMiddleware implements MiddlewareInterface
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    public function process(Request $request, RequestHandler $handler): Response
    {
        // AuthMiddleware must have already run and attached the decoded JWT
        $admin = $request->getAttribute('admin');
        if ($admin === null) {
            return $this->error(401, 'Authentication required before tenant resolution');
        }

        $tenantId = $admin->tenant_id ?? null;

        if (empty($tenantId)) {
            return $this->error(400, 'JWT is missing required claim: tenant_id');
        }

        // Validate UUID format to prevent SQL injection (defence-in-depth)
        if (!preg_match(
            '/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i',
            $tenantId
        )) {
            return $this->error(400, 'Invalid tenant_id format in JWT');
        }

        $stmt = $this->db->prepare(
            'SELECT id, name, slug, plan, status, settings FROM tenants WHERE id = ? LIMIT 1'
        );
        $stmt->execute([$tenantId]);
        $tenant = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($tenant === false) {
            return $this->error(404, 'Tenant not found');
        }

        if ($tenant['status'] !== 'active') {
            return $this->error(403, 'Tenant account is suspended or deleted');
        }

        // Decode JSON settings field
        if (isset($tenant['settings']) && is_string($tenant['settings'])) {
            $tenant['settings'] = json_decode($tenant['settings'], true) ?? [];
        }

        $request = $request->withAttribute('tenant', $tenant);
        $request = $request->withAttribute('tenant_id', $tenantId);

        return $handler->handle($request);
    }

    /** Emit a JSON error response. */
    private function error(int $status, string $message): Response
    {
        $response = new \Slim\Psr7\Response();
        $response->getBody()->write(json_encode([
            'error'   => $this->statusLabel($status),
            'message' => $message,
        ], JSON_UNESCAPED_UNICODE));

        return $response
            ->withStatus($status)
            ->withHeader('Content-Type', 'application/json');
    }

    private function statusLabel(int $status): string
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
