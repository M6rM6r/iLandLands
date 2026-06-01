<?php

namespace App\Services;

/**
 * AuditLogService — append-only mutation audit trail (Slim 4).
 *
 * Ported from Rew (realestate-saas) lib/audit.ts.
 * Errors are caught internally — the caller's operation is never disrupted.
 */
class AuditLogService
{
    private const ALLOWED_ACTIONS   = ['create', 'update', 'delete', 'publish'];
    private const ALLOWED_RESOURCES = ['listing', 'inquiry', 'announcement', 'profile', 'gallery', 'team', 'payment'];

    public function __construct(private \PDO $db) {}

    /**
     * @param string               $tenantId
     * @param string               $action      create|update|delete|publish
     * @param string               $resource    listing|inquiry|announcement|profile|gallery|team|payment
     * @param string               $resourceId
     * @param string               $userId
     * @param array<string,mixed>|null  $before  State before mutation (omit on create)
     * @param array<string,mixed>|null  $after   State after mutation (omit on delete)
     */
    public function logMutation(
        string $tenantId,
        string $action,
        string $resource,
        string $resourceId,
        string $userId,
        ?array $before = null,
        ?array $after  = null
    ): void {
        if (!in_array($action, self::ALLOWED_ACTIONS, true)) return;
        if (!in_array($resource, self::ALLOWED_RESOURCES, true)) return;

        try {
            $ipAddress = $_SERVER['REMOTE_ADDR'] ?? null;

            $stmt = $this->db->prepare(
                'INSERT INTO audit_logs
                     (tenant_id, action, resource, resource_id, user_id, before, after, ip_address, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())'
            );
            $stmt->execute([
                $tenantId,
                $action,
                $resource,
                $resourceId,
                $userId,
                $before !== null ? json_encode($before, JSON_UNESCAPED_UNICODE) : null,
                $after  !== null ? json_encode($after,  JSON_UNESCAPED_UNICODE) : null,
                $ipAddress,
            ]);
        } catch (\Throwable $e) {
            error_log('AuditLogService::logMutation error: ' . $e->getMessage());
        }
    }
}
