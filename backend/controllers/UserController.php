<?php

declare(strict_types=1);

/**
 * UserController — Admin user management and profile endpoints.
 *
 * GET    /api/v1/users       — List users (admin/manager)
 * GET    /api/v1/users/me    — Current user profile (any auth)
 * GET    /api/v1/users/{id}  — Get single user (admin/manager)
 * PATCH  /api/v1/users/{id}  — Update user (admin/manager)
 * DELETE /api/v1/users/{id}  — Soft-delete user (admin only)
 */
class UserController
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    // =========================================================================
    // GET /api/v1/users
    // =========================================================================
    public function list(): void
    {
        $this->requireRole(['admin', 'manager']);
        $tenantId = $this->getTenantId();

        $role   = $_GET['role'] ?? null;
        $status = $_GET['status'] ?? null;
        $page   = max(1, (int) ($_GET['page'] ?? 1));
        $limit  = min(100, max(1, (int) ($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;

        $where  = ['tenant_id = ?'];
        $params = [$tenantId];

        if ($role !== null && in_array($role, ['admin', 'manager', 'agent', 'viewer'], true)) {
            $where[]  = 'role = ?';
            $params[] = $role;
        }
        if ($status !== null && in_array($status, ['active', 'inactive', 'suspended'], true)) {
            $where[]  = 'status = ?';
            $params[] = $status;
        }

        $sql = 'SELECT id, email, first_name, last_name, phone, role, country, status, email_verified, created_at
                FROM users
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?';
        $params[] = $limit;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Count
        $countSql = 'SELECT COUNT(*) FROM users WHERE ' . implode(' AND ', array_slice($where, 0, count($where)));
        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute(array_slice($params, 0, count($params) - 2));
        $total = (int) $countStmt->fetchColumn();

        $this->respond(200, [
            'data'       => $rows,
            'pagination' => [
                'page'  => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => (int) ceil($total / $limit),
            ],
        ]);
    }

    // =========================================================================
    // GET /api/v1/users/me
    // =========================================================================
    public function me(): void
    {
        $authUser = $_REQUEST['_auth_user'] ?? null;
        if ($authUser === null || !isset($authUser['sub'])) {
            $this->respond(401, ['error' => 'Authentication required']);
        }

        $stmt = $this->db->prepare(
            'SELECT id, tenant_id, email, first_name, last_name, phone, role, country, status, email_verified, created_at
             FROM users WHERE id = ? LIMIT 1'
        );
        $stmt->execute([(string) $authUser['sub']]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            $this->respond(404, ['error' => 'User not found']);
        }

        $this->respond(200, $row);
    }

    // =========================================================================
    // GET /api/v1/users/{id}
    // =========================================================================
    public function get(string $id): void
    {
        $this->requireRole(['admin', 'manager']);
        $tenantId = $this->getTenantId();

        $stmt = $this->db->prepare(
            'SELECT id, tenant_id, email, first_name, last_name, phone, role, country, status, email_verified, created_at
             FROM users WHERE id = ? AND tenant_id = ? LIMIT 1'
        );
        $stmt->execute([$id, $tenantId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            $this->respond(404, ['error' => 'User not found']);
        }

        $this->respond(200, $row);
    }

    // =========================================================================
    // PATCH /api/v1/users/{id}
    // =========================================================================
    public function update(string $id): void
    {
        $this->requireRole(['admin', 'manager']);
        $tenantId = $this->getTenantId();
        $authRole = $this->getAuthRole();

        $body      = $this->parseJsonBody();
        $updates   = [];
        $params    = [];

        // Managers cannot update admins
        if ($authRole === 'manager') {
            $stmt = $this->db->prepare('SELECT role FROM users WHERE id = ? AND tenant_id = ? LIMIT 1');
            $stmt->execute([$id, $tenantId]);
            $targetRole = $stmt->fetchColumn();
            if ($targetRole === 'admin') {
                $this->respond(403, ['error' => 'Managers cannot modify admin accounts']);
            }
        }

        if (array_key_exists('first_name', $body)) {
            $updates[] = 'first_name = ?';
            $params[]  = $body['first_name'] !== '' ? $body['first_name'] : null;
        }
        if (array_key_exists('last_name', $body)) {
            $updates[] = 'last_name = ?';
            $params[]  = $body['last_name'] !== '' ? $body['last_name'] : null;
        }
        if (array_key_exists('phone', $body)) {
            $updates[] = 'phone = ?';
            $params[]  = $body['phone'] !== '' ? $body['phone'] : null;
        }
        if (array_key_exists('country', $body)) {
            $allowed = ['saudiArabia', 'uae', 'qatar', 'bahrain', 'oman', 'kuwait'];
            if (in_array($body['country'], $allowed, true)) {
                $updates[] = 'country = ?';
                $params[]  = $body['country'];
            }
        }
        if (array_key_exists('status', $body) && in_array($body['status'], ['active', 'inactive', 'suspended'], true)) {
            $updates[] = 'status = ?';
            $params[]  = $body['status'];
        }
        if (array_key_exists('role', $body) && in_array($body['role'], ['admin', 'manager', 'agent', 'viewer'], true)) {
            // Only admins can change roles
            if ($authRole !== 'admin') {
                $this->respond(403, ['error' => 'Only admins can change user roles']);
            }
            $updates[] = 'role = ?';
            $params[]  = $body['role'];
        }

        if (empty($updates)) {
            $this->respond(422, ['error' => 'No valid fields to update']);
        }

        $params[] = $id;
        $params[] = $tenantId;

        $stmt = $this->db->prepare(
            'UPDATE users SET ' . implode(', ', $updates) . ', updated_at = NOW() WHERE id = ? AND tenant_id = ?'
        );
        $stmt->execute($params);

        if ($stmt->rowCount() === 0) {
            $this->respond(404, ['error' => 'User not found or no changes made']);
        }

        $this->respond(200, ['id' => $id, 'updated' => true]);
    }

    // =========================================================================
    // DELETE /api/v1/users/{id}
    // =========================================================================
    public function delete(string $id): void
    {
        $this->requireRole(['admin']);
        $tenantId = $this->getTenantId();

        // Prevent self-deletion
        $authUser = $_REQUEST['_auth_user'] ?? null;
        if ($authUser !== null && ($authUser['sub'] ?? '') === $id) {
            $this->respond(403, ['error' => 'Cannot delete your own account']);
        }

        $stmt = $this->db->prepare(
            'UPDATE users SET status = \'inactive\', updated_at = NOW() WHERE id = ? AND tenant_id = ?'
        );
        $stmt->execute([$id, $tenantId]);

        if ($stmt->rowCount() === 0) {
            $this->respond(404, ['error' => 'User not found']);
        }

        $this->respond(200, ['id' => $id, 'deleted' => true]);
    }

    // =========================================================================
    // PATCH /api/v1/users/me
    // =========================================================================
    public function updateProfile(): void
    {
        $authUser = $_REQUEST['_auth_user'] ?? null;
        if ($authUser === null || !isset($authUser['sub'])) {
            $this->respond(401, ['error' => 'Authentication required']);
        }

        $body    = $this->parseJsonBody();
        $updates = [];
        $params  = [];

        if (array_key_exists('first_name', $body)) {
            $updates[] = 'first_name = ?';
            $params[]  = $body['first_name'] !== '' ? $body['first_name'] : null;
        }
        if (array_key_exists('last_name', $body)) {
            $updates[] = 'last_name = ?';
            $params[]  = $body['last_name'] !== '' ? $body['last_name'] : null;
        }
        if (array_key_exists('phone', $body)) {
            $updates[] = 'phone = ?';
            $params[]  = $body['phone'] !== '' ? $body['phone'] : null;
        }
        if (array_key_exists('country', $body)) {
            $allowed = ['saudiArabia', 'uae', 'qatar', 'bahrain', 'oman', 'kuwait'];
            if (in_array($body['country'], $allowed, true)) {
                $updates[] = 'country = ?';
                $params[]  = $body['country'];
            }
        }

        if (empty($updates)) {
            $this->respond(422, ['error' => 'No valid fields to update']);
        }

        $params[] = (string) $authUser['sub'];

        $stmt = $this->db->prepare(
            'UPDATE users SET ' . implode(', ', $updates) . ', updated_at = NOW() WHERE id = ?'
        );
        $stmt->execute($params);

        $this->respond(200, ['updated' => true]);
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    private function getTenantId(): string
    {
        $tenant = $_REQUEST['_tenant'] ?? null;
        if ($tenant !== null && isset($tenant['id'])) {
            return (string) $tenant['id'];
        }
        $this->respond(400, ['error' => 'Tenant context missing']);
    }

    private function getAuthRole(): string
    {
        $authUser = $_REQUEST['_auth_user'] ?? null;
        return $authUser['role'] ?? 'viewer';
    }

    private function requireRole(array $allowedRoles): void
    {
        $authUser = $_REQUEST['_auth_user'] ?? null;
        if ($authUser === null) {
            $this->respond(401, ['error' => 'Authentication required']);
        }
        $role = $authUser['role'] ?? 'viewer';
        if (!in_array($role, $allowedRoles, true)) {
            $this->respond(403, ['error' => 'Insufficient permissions']);
        }
    }

    private function parseJsonBody(): array
    {
        $raw = file_get_contents('php://input');
        if ($raw === '') {
            return [];
        }
        $decoded = json_decode($raw, true, 512, JSON_THROW_ON_ERROR);
        return is_array($decoded) ? $decoded : [];
    }

    private function respond(int $code, array $data): never
    {
        http_response_code($code);
        header('Content-Type: application/json');
        echo json_encode($data, JSON_UNESCAPED_UNICODE);
        exit;
    }
}
