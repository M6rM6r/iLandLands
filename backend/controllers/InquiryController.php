<?php
/**
 * InquiryController — Handles property contact inquiries.
 *
 * POST /api/v1/inquiries       — Submit a new inquiry (public, rate-limited)
 * GET  /api/v1/inquiries       — List inquiries for tenant (auth: admin/manager)
 * GET  /api/v1/inquiries/{id}  — Get single inquiry (auth: admin/manager)
 * PATCH /api/v1/inquiries/{id} — Update inquiry status (auth: admin/manager)
 *
 * Side effects on POST (best-effort, non-fatal):
 *   1. WhatsApp notification sent to all configured agent numbers.
 *   2. HubSpot Contact upsert + Deal creation.
 */

require_once __DIR__ . '/../services/WhatsAppService.php';
require_once __DIR__ . '/../services/HubSpotService.php';
require_once __DIR__ . '/../services/LeadScoringService.php';
require_once __DIR__ . '/../services/FunnelEventService.php';

class InquiryController
{
    private PDO                 $db;
    private WhatsAppService     $whatsapp;
    private HubSpotService      $hubspot;
    private LeadScoringService  $leadScoring;
    private FunnelEventService  $funnel;

    private const ALLOWED_STATUSES = ['new', 'read', 'replied', 'closed'];

    public function __construct(PDO $db)
    {
        $this->db          = $db;
        $this->whatsapp    = new WhatsAppService();
        $this->hubspot     = new HubSpotService();
        $this->leadScoring = new LeadScoringService();
        $this->funnel      = new FunnelEventService($db);
    }

    // =========================================================================
    // POST /api/v1/inquiries
    // =========================================================================
    public function create(): void
    {
        $body    = $this->parseJsonBody();
        $tenantId = (string) ($_REQUEST['_tenant_id'] ?? '');

        $name    = trim($body['name']    ?? '');
        $email   = trim($body['email']   ?? '');
        $phone   = trim($body['phone']   ?? '');
        $message = trim($body['message'] ?? '');
        $landId  = trim($body['land_id'] ?? '');
        $userId  = trim($body['user_id'] ?? '');

        // --- Validation ---
        if ($name === '') {
            $this->respond(422, ['error' => 'name is required']);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->respond(422, ['error' => 'Valid email is required']);
        }
        if (strlen($message) < 10) {
            $this->respond(422, ['error' => 'message must be at least 10 characters']);
        }
        if ($tenantId === '') {
            $this->respond(400, ['error' => 'Tenant context missing']);
        }

        // --- Resolve listing title for notifications ---
        $landTitle = '';
        if ($landId !== '') {
            $st = $this->db->prepare(
                'SELECT title FROM land_listings WHERE id = ? AND tenant_id = ? LIMIT 1'
            );
            $st->execute([$landId, $tenantId]);
            $row = $st->fetch(PDO::FETCH_ASSOC);
            $landTitle = $row ? (string) $row['title'] : '';
        }

        // --- Lead scoring (synchronous, no I/O) ---
        $leadResult = $this->leadScoring->score([
            'name'    => $name,
            'phone'   => $phone,
            'email'   => $email,
            'message' => $message,
            'land_id' => $landId,
        ]);

        // --- Persist ---
        $id = $this->generateUuid();
        $stmt = $this->db->prepare(
            'INSERT INTO contact_inquiries
                 (id, tenant_id, land_id, user_id, name, email, phone, message, status, lead_score, lead_band, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, \'new\', ?, ?, NOW())'
        );
        $stmt->execute([
            $id,
            $tenantId,
            $landId  !== '' ? $landId : null,
            $userId  !== '' ? $userId : null,
            $name,
            $email,
            $phone   !== '' ? $phone : null,
            $message,
            $leadResult['score'],
            $leadResult['band'],
        ]);

        // --- Best-effort side effects (errors logged, not thrown) ---
        $inquiryData = [
            'id'         => $id,
            'name'       => $name,
            'email'      => $email,
            'phone'      => $phone  !== '' ? $phone : null,
            'message'    => $message,
            'land_title' => $landTitle,
            'land_id'    => $landId  !== '' ? $landId : null,
            'tenant_id'  => $tenantId,
        ];

        $this->whatsapp->notifyAgentsNewInquiry($inquiryData);
        $this->hubspot->createInquiryDeal($inquiryData);
        $this->funnel->track('inquiry_created', $tenantId, [
            'inquiry_id' => $id,
            'land_id'    => $landId  !== '' ? $landId : null,
            'lead_score' => $leadResult['score'],
            'lead_band'  => $leadResult['band'],
        ]);

        $this->respond(201, ['id' => $id, 'status' => 'new', 'lead_score' => $leadResult['score'], 'lead_band' => $leadResult['band']]);
    }

    // =========================================================================
    // GET /api/v1/inquiries
    // =========================================================================
    public function list(): void
    {
        $tenantId = (string) ($_REQUEST['_tenant_id'] ?? '');
        if ($tenantId === '') {
            $this->respond(400, ['error' => 'Tenant context missing']);
        }

        $status = $_GET['status'] ?? null;
        $landId = $_GET['land_id'] ?? null;
        $page   = max(1, (int) ($_GET['page'] ?? 1));
        $limit  = min(100, max(1, (int) ($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;

        $where  = ['i.tenant_id = ?'];
        $params = [$tenantId];

        if ($status !== null && in_array($status, self::ALLOWED_STATUSES, true)) {
            $where[]  = 'i.status = ?';
            $params[] = $status;
        }
        if ($landId !== null) {
            $where[]  = 'i.land_id = ?';
            $params[] = $landId;
        }

        $sql = 'SELECT i.id, i.land_id, i.name, i.email, i.phone,
                       LEFT(i.message, 200) AS message_preview, i.status,
                       i.lead_score, i.lead_band, i.created_at,
                       l.title AS land_title
                FROM contact_inquiries i
                LEFT JOIN land_listings l ON l.id = i.land_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY i.created_at DESC
                LIMIT ? OFFSET ?';

        $params[] = $limit;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Count
        $countSql = 'SELECT COUNT(*) FROM contact_inquiries i WHERE ' .
                    implode(' AND ', array_slice($where, 0));
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
    // GET /api/v1/inquiries/{id}
    // =========================================================================
    public function get(string $id): void
    {
        $tenantId = (string) ($_REQUEST['_tenant_id'] ?? '');

        $stmt = $this->db->prepare(
            'SELECT i.*, l.title AS land_title
             FROM contact_inquiries i
             LEFT JOIN land_listings l ON l.id = i.land_id
             WHERE i.id = ? AND i.tenant_id = ? LIMIT 1'
        );
        $stmt->execute([$id, $tenantId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            $this->respond(404, ['error' => 'Inquiry not found']);
        }

        $this->respond(200, $row);
    }

    // =========================================================================
    // PATCH /api/v1/inquiries/{id}
    // =========================================================================
    public function update(string $id): void
    {
        $tenantId = (string) ($_REQUEST['_tenant_id'] ?? '');
        $body     = $this->parseJsonBody();
        $status   = $body['status'] ?? '';

        if (!in_array($status, self::ALLOWED_STATUSES, true)) {
            $this->respond(422, ['error' => 'status must be one of: ' . implode(', ', self::ALLOWED_STATUSES)]);
        }

        $stmt = $this->db->prepare(
            'UPDATE contact_inquiries SET status = ?, updated_at = NOW() WHERE id = ? AND tenant_id = ?'
        );
        $stmt->execute([$status, $id, $tenantId]);

        if ($stmt->rowCount() === 0) {
            $this->respond(404, ['error' => 'Inquiry not found']);
        }

        $this->respond(200, ['id' => $id, 'status' => $status]);
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

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
        echo json_encode($data, JSON_UNESCAPED_UNICODE);
        exit();
    }

    private function generateUuid(): string
    {
        $data    = random_bytes(16);
        $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
        $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
    }
}
