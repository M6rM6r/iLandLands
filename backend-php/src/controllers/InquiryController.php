<?php

namespace App\Controllers;

use PDO;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Services\WhatsAppService;
use App\Services\HubSpotService;
use App\Services\LeadScoringService;
use App\Services\FunnelEventService;

/**
 * InquiryController — Slim 4 PSR-7 version.
 *
 * Routes (registered in Routes.php):
 *   POST   /api/inquiries          → create()  (public, rate-limited)
 *   GET    /api/inquiries          → list()    (auth: admin/manager/viewer + tenant)
 *   GET    /api/inquiries/{id}     → get()     (auth: admin/manager/viewer + tenant)
 *   PATCH  /api/inquiries/{id}     → update()  (auth: admin/manager + tenant)
 */
class InquiryController
{
    private PDO                $db;
    private WhatsAppService    $whatsapp;
    private HubSpotService     $hubspot;
    private LeadScoringService $leadScoring;
    private FunnelEventService $funnel;

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
    // POST /api/inquiries  (public)
    // =========================================================================
    public function create(Request $request, Response $response): Response
    {
        $body     = (array) ($request->getParsedBody() ?? []);
        $tenantId = (string) ($request->getAttribute('tenant_id') ?? '');

        $name    = trim($body['name']    ?? '');
        $email   = trim($body['email']   ?? '');
        $phone   = trim($body['phone']   ?? '');
        $message = trim($body['message'] ?? '');
        $landId  = trim($body['land_id'] ?? '');
        $userId  = trim($body['user_id'] ?? '');

        // --- Validation ---
        $errors = [];
        if ($name === '') {
            $errors[] = 'name is required';
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = 'Valid email is required';
        }
        if (strlen($message) < 10) {
            $errors[] = 'message must be at least 10 characters';
        }
        if ($tenantId === '') {
            $errors[] = 'Tenant context missing';
        }
        if (!empty($errors)) {
            $response->getBody()->write(json_encode(['errors' => $errors]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
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
        $id   = $this->generateUuid();
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

        // --- Best-effort side effects ---
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

        $response->getBody()->write(json_encode([
            'id'         => $id,
            'status'     => 'new',
            'lead_score' => $leadResult['score'],
            'lead_band'  => $leadResult['band'],
        ]));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
    }

    // =========================================================================
    // GET /api/inquiries  (auth)
    // =========================================================================
    public function list(Request $request, Response $response): Response
    {
        $tenantId = (string) ($request->getAttribute('tenant_id') ?? '');
        $params   = $request->getQueryParams();

        $status = $params['status'] ?? null;
        $landId = $params['land_id'] ?? null;
        $page   = max(1, (int) ($params['page'] ?? 1));
        $limit  = min(100, max(1, (int) ($params['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;

        $where  = ['i.tenant_id = ?'];
        $bind   = [$tenantId];

        if ($status !== null && in_array($status, self::ALLOWED_STATUSES, true)) {
            $where[] = 'i.status = ?';
            $bind[]  = $status;
        }
        if ($landId !== null) {
            $where[] = 'i.land_id = ?';
            $bind[]  = $landId;
        }

        $whereClause = implode(' AND ', $where);

        $stmt = $this->db->prepare(
            "SELECT i.id, i.land_id, i.name, i.email, i.phone,
                    LEFT(i.message, 200) AS message_preview, i.status,
                    i.lead_score, i.lead_band, i.created_at,
                    l.title AS land_title
             FROM contact_inquiries i
             LEFT JOIN land_listings l ON l.id = i.land_id
             WHERE $whereClause
             ORDER BY i.created_at DESC
             LIMIT ? OFFSET ?"
        );
        $stmt->execute([...$bind, $limit, $offset]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $countStmt = $this->db->prepare("SELECT COUNT(*) FROM contact_inquiries i WHERE $whereClause");
        $countStmt->execute($bind);
        $total = (int) $countStmt->fetchColumn();

        $payload = [
            'data'       => $rows,
            'pagination' => [
                'page'  => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => (int) ceil($total / $limit),
            ],
        ];

        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
    }

    // =========================================================================
    // GET /api/inquiries/{id}  (auth)
    // =========================================================================
    public function get(Request $request, Response $response, array $args): Response
    {
        $tenantId = (string) ($request->getAttribute('tenant_id') ?? '');
        $id       = (string) ($args['id'] ?? '');

        $stmt = $this->db->prepare(
            'SELECT i.*, l.title AS land_title
             FROM contact_inquiries i
             LEFT JOIN land_listings l ON l.id = i.land_id
             WHERE i.id = ? AND i.tenant_id = ? LIMIT 1'
        );
        $stmt->execute([$id, $tenantId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            $response->getBody()->write(json_encode(['error' => 'Inquiry not found']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        }

        $response->getBody()->write(json_encode($row));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
    }

    // =========================================================================
    // PATCH /api/inquiries/{id}  (auth)
    // =========================================================================
    public function update(Request $request, Response $response, array $args): Response
    {
        $tenantId = (string) ($request->getAttribute('tenant_id') ?? '');
        $id       = (string) ($args['id'] ?? '');
        $body     = (array) ($request->getParsedBody() ?? []);
        $status   = (string) ($body['status'] ?? '');

        if (!in_array($status, self::ALLOWED_STATUSES, true)) {
            $response->getBody()->write(json_encode([
                'error' => 'status must be one of: ' . implode(', ', self::ALLOWED_STATUSES),
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        }

        $stmt = $this->db->prepare(
            'UPDATE contact_inquiries SET status = ?, updated_at = NOW() WHERE id = ? AND tenant_id = ?'
        );
        $stmt->execute([$status, $id, $tenantId]);

        if ($stmt->rowCount() === 0) {
            $response->getBody()->write(json_encode(['error' => 'Inquiry not found']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        }

        $response->getBody()->write(json_encode(['id' => $id, 'status' => $status]));
        return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
    }

    // =========================================================================
    // Private helpers
    // =========================================================================

    private function generateUuid(): string
    {
        $data    = random_bytes(16);
        $data[6] = chr(ord($data[6]) & 0x0f | 0x40);
        $data[8] = chr(ord($data[8]) & 0x3f | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
    }
}
