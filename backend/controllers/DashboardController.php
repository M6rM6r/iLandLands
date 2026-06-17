<?php

declare(strict_types=1);

/**
 * DashboardController — Aggregated analytics and metrics for the admin dashboard.
 *
 * GET /api/v1/dashboard/metrics — High-level KPIs
 * GET /api/v1/dashboard/inquiry-pipeline — Inquiry counts by status
 * GET /api/v1/dashboard/recent-activity — Recent events
 */
class DashboardController
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    // =========================================================================
    // GET /api/v1/dashboard/metrics
    // =========================================================================
    public function metrics(): void
    {
        $this->requireRole(['admin', 'manager', 'agent']);
        $tenantId = $this->getTenantId();

        // Total listings
        $stmt = $this->db->prepare('SELECT COUNT(*) FROM land_listings WHERE tenant_id = ?');
        $stmt->execute([$tenantId]);
        $totalListings = (int) $stmt->fetchColumn();

        // Active listings
        $stmt = $this->db->prepare("SELECT COUNT(*) FROM land_listings WHERE tenant_id = ? AND status = 'active'");
        $stmt->execute([$tenantId]);
        $activeListings = (int) $stmt->fetchColumn();

        // Total inquiries
        $stmt = $this->db->prepare('SELECT COUNT(*) FROM contact_inquiries WHERE tenant_id = ?');
        $stmt->execute([$tenantId]);
        $totalInquiries = (int) $stmt->fetchColumn();

        // New inquiries today
        $stmt = $this->db->prepare(
            "SELECT COUNT(*) FROM contact_inquiries WHERE tenant_id = ? AND DATE(created_at) = CURDATE()"
        );
        $stmt->execute([$tenantId]);
        $newInquiriesToday = (int) $stmt->fetchColumn();

        // Active (non-closed) inquiries
        $stmt = $this->db->prepare(
            "SELECT COUNT(*) FROM contact_inquiries WHERE tenant_id = ? AND status NOT IN ('won', 'lost', 'closed')"
        );
        $stmt->execute([$tenantId]);
        $activeInquiries = (int) $stmt->fetchColumn();

        // Total users
        $stmt = $this->db->prepare("SELECT COUNT(*) FROM users WHERE tenant_id = ? AND status = 'active'");
        $stmt->execute([$tenantId]);
        $totalUsers = (int) $stmt->fetchColumn();

        // Conversion rate: won / total inquiries (excluding new today to avoid skew)
        $stmt = $this->db->prepare(
            "SELECT COUNT(*) FROM contact_inquiries WHERE tenant_id = ? AND status = 'won'"
        );
        $stmt->execute([$tenantId]);
        $wonDeals = (int) $stmt->fetchColumn();

        $conversionRate = $totalInquiries > 0 ? round(($wonDeals / $totalInquiries) * 100, 2) : 0.0;

        // Average deal value (won deals with land_id)
        $stmt = $this->db->prepare(
            "SELECT AVG(ll.price)
             FROM contact_inquiries ci
             JOIN land_listings ll ON ll.id = ci.land_id
             WHERE ci.tenant_id = ? AND ci.status = 'won'"
        );
        $stmt->execute([$tenantId]);
        $avgDealValue = (float) ($stmt->fetchColumn() ?? 0);

        // Inquiry pipeline breakdown
        $stmt = $this->db->prepare(
            "SELECT status, COUNT(*) as cnt
             FROM contact_inquiries
             WHERE tenant_id = ?
             GROUP BY status"
        );
        $stmt->execute([$tenantId]);
        $pipelineRows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $pipeline = [];
        foreach ($pipelineRows as $row) {
            $pipeline[$row['status']] = (int) $row['cnt'];
        }

        // Listings by country
        $stmt = $this->db->prepare(
            "SELECT country, COUNT(*) as cnt
             FROM land_listings
             WHERE tenant_id = ? AND status = 'active'
             GROUP BY country"
        );
        $stmt->execute([$tenantId]);
        $countryRows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $listingsByCountry = [];
        foreach ($countryRows as $row) {
            $listingsByCountry[$row['country']] = (int) $row['cnt'];
        }

        $this->respond(200, [
            'metrics' => [
                'totalListings'      => $totalListings,
                'activeListings'     => $activeListings,
                'totalInquiries'     => $totalInquiries,
                'activeInquiries'    => $activeInquiries,
                'newInquiriesToday'  => $newInquiriesToday,
                'totalUsers'         => $totalUsers,
                'wonDeals'           => $wonDeals,
                'conversionRate'     => $conversionRate,
                'avgDealValue'       => round($avgDealValue, 2),
            ],
            'pipeline'            => $pipeline,
            'listingsByCountry'   => $listingsByCountry,
        ]);
    }

    // =========================================================================
    // GET /api/v1/dashboard/inquiry-pipeline
    // =========================================================================
    public function inquiryPipeline(): void
    {
        $this->requireRole(['admin', 'manager', 'agent']);
        $tenantId = $this->getTenantId();

        $stmt = $this->db->prepare(
            "SELECT status, COUNT(*) as cnt
             FROM contact_inquiries
             WHERE tenant_id = ?
             GROUP BY status
             ORDER BY FIELD(status, 'new','contacted','scheduled','visited','negotiating','won','lost','read','replied','closed')"
        );
        $stmt->execute([$tenantId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $pipeline = [];
        foreach ($rows as $row) {
            $pipeline[$row['status']] = (int) $row['cnt'];
        }

        $this->respond(200, ['pipeline' => $pipeline]);
    }

    // =========================================================================
    // GET /api/v1/dashboard/recent-activity
    // =========================================================================
    public function recentActivity(): void
    {
        $this->requireRole(['admin', 'manager', 'agent']);
        $tenantId = $this->getTenantId();

        $limit = min(50, max(1, (int) ($_GET['limit'] ?? 20)));

        $stmt = $this->db->prepare(
            "SELECT event_name, user_id, properties, created_at
             FROM analytics_events
             WHERE tenant_id = ?
             ORDER BY created_at DESC
             LIMIT ?"
        );
        $stmt->execute([$tenantId, $limit]);
        $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $this->respond(200, ['events' => $events]);
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

    private function respond(int $code, array $data): never
    {
        http_response_code($code);
        header('Content-Type: application/json');
        echo json_encode($data, JSON_UNESCAPED_UNICODE);
        exit;
    }
}
