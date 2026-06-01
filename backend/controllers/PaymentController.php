<?php
/**
 * PaymentController — handles Telr payment lifecycle endpoints.
 *
 * Routes (added to index.php switch):
 *   POST   /api/v1/payments/initiate   → initiate()
 *   POST   /api/v1/payments/callback   → callback()  (Telr webhook — NOT auth-gated)
 *   GET    /api/v1/payments/return     → returnRedirect()
 *   GET    /api/v1/payments/cancel     → cancelRedirect()
 *   GET    /api/v1/payments/{orderId}  → status()
 */

require_once __DIR__ . '/../services/TelrPaymentService.php';
require_once __DIR__ . '/../services/FunnelEventService.php';

class PaymentController
{
    private PDO                $db;
    private TelrPaymentService $telr;
    private FunnelEventService $funnel;

    public function __construct(PDO $db)
    {
        $this->db     = $db;
        $this->telr   = new TelrPaymentService();
        $this->funnel = new FunnelEventService($db);
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/payments/initiate
    // Requires: JWT auth + tenant context (set by middleware)
    // -------------------------------------------------------------------------
    public function initiate(): void
    {
        $input = $this->decodeJsonBody();

        $tenantId = $_REQUEST['_tenant_id'] ?? null;
        if (!$tenantId) {
            http_response_code(403);
            echo json_encode(['error' => 'Tenant context required']);
            return;
        }

        $userId = $_REQUEST['_auth_user']['id'] ?? null;

        // Build a unique cart ID: tenant + timestamp + random
        $cartId = sprintf(
            '%s-%s-%s',
            substr((string) $tenantId, 0, 8),
            date('YmdHis'),
            bin2hex(random_bytes(4))
        );

        // Persist pending payment record
        $stmt = $this->db->prepare('
            INSERT INTO payments (cart_id, tenant_id, user_id, listing_id, amount, currency, status, created_at)
            VALUES (:cart_id, :tenant_id, :user_id, :listing_id, :amount, :currency, "pending", NOW())
        ');
        $stmt->execute([
            ':cart_id'    => $cartId,
            ':tenant_id'  => $tenantId,
            ':user_id'    => $userId,
            ':listing_id' => $input['listing_id'] ?? null,
            ':amount'     => $input['amount'],
            ':currency'   => strtoupper((string) ($input['currency'] ?? 'AED')),
        ]);

        try {
            $result = $this->telr->initiate([
                'cart_id'     => $cartId,
                'amount'      => $input['amount'],
                'currency'    => strtoupper((string) ($input['currency'] ?? 'AED')),
                'description' => $input['description'] ?? 'Gulflands property payment',
                'customer'    => $input['customer'] ?? [],
            ], (string) $tenantId);

            // Store Telr order reference
            $update = $this->db->prepare('UPDATE payments SET telr_order_id = :ref WHERE cart_id = :cart_id');
            $update->execute([':ref' => $result['order_id'], ':cart_id' => $cartId]);

            http_response_code(201);
            echo json_encode([
                'cart_id'     => $cartId,
                'order_id'    => $result['order_id'],
                'payment_url' => $result['payment_url'],
            ]);
        } catch (InvalidArgumentException $e) {
            http_response_code(422);
            echo json_encode(['error' => $e->getMessage()]);
        } catch (RuntimeException $e) {
            error_log('Telr initiate error: ' . $e->getMessage());
            http_response_code(502);
            echo json_encode(['error' => 'Payment gateway unavailable']);
        }
    }

    // -------------------------------------------------------------------------
    // POST /api/v1/payments/callback
    // Called by Telr server-to-server (NOT auth-gated — validated by Telr fields)
    // -------------------------------------------------------------------------
    public function callback(): void
    {
        // Telr posts form data (application/x-www-form-urlencoded)
        $cartId  = $_POST['cart_id']  ?? '';
        $orderId = $_POST['order_id'] ?? '';
        $status  = $_POST['status']   ?? '';

        if ($cartId === '' || $orderId === '') {
            http_response_code(400);
            echo json_encode(['error' => 'Missing cart_id or order_id']);
            return;
        }

        // Double-check status with Telr (never trust inbound status alone)
        try {
            $verified = $this->telr->verify($orderId);
            $statusCode = $verified['code'];

            // Telr status codes: 3 = authorised, 2 = declined, 0 = pending
            $mappedStatus = match (true) {
                $statusCode === '3' => 'completed',
                in_array($statusCode, ['2', '6'], true) => 'failed',
                default => 'pending',
            };

            $stmt = $this->db->prepare('
                UPDATE payments
                SET status = :status, telr_order_id = :order_id, updated_at = NOW()
                WHERE cart_id = :cart_id
            ');
            $stmt->execute([
                ':status'   => $mappedStatus,
                ':order_id' => $orderId,
                ':cart_id'  => $cartId,
            ]);

            // Funnel event — best effort
            $funnelEvent = $mappedStatus === 'completed' ? 'payment_succeeded'
                         : ($mappedStatus === 'failed'    ? 'payment_failed' : null);
            if ($funnelEvent !== null) {
                $row = $this->db->prepare('SELECT tenant_id FROM payments WHERE cart_id = ? LIMIT 1');
                $row->execute([$cartId]);
                $tenantId = (string) ($row->fetchColumn() ?: '');
                $this->funnel->track($funnelEvent, $tenantId, [
                    'cart_id'  => $cartId,
                    'order_id' => $orderId,
                    'status'   => $mappedStatus,
                ]);
            }

            http_response_code(200);
            echo json_encode(['received' => true]);
        } catch (RuntimeException $e) {
            error_log('Telr callback verify error: ' . $e->getMessage());
            http_response_code(502);
            echo json_encode(['error' => 'Verification failed']);
        }
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/payments/return?status=auth|decl&tenant_id=...&cart_id=...
    // Browser redirect after payment attempt
    // -------------------------------------------------------------------------
    public function returnRedirect(): void
    {
        $status   = $_GET['status']    ?? 'unknown';
        $tenantId = $_GET['tenant_id'] ?? '';

        $appUrl = rtrim((string) ($_ENV['APP_FRONTEND_URL'] ?? getenv('APP_FRONTEND_URL') ?? 'https://app.gulflands.com'), '/');

        $redirectStatus = ($status === 'auth') ? 'success' : 'declined';
        $redirectUrl = $appUrl . '/payment/' . urlencode($redirectStatus);

        header('Location: ' . $redirectUrl);
        http_response_code(302);
        exit;
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/payments/cancel?tenant_id=...
    // Browser redirect when user cancels on the Telr page
    // -------------------------------------------------------------------------
    public function cancelRedirect(): void
    {
        $appUrl = rtrim((string) ($_ENV['APP_FRONTEND_URL'] ?? getenv('APP_FRONTEND_URL') ?? 'https://app.gulflands.com'), '/');

        header('Location: ' . $appUrl . '/payment/cancelled');
        http_response_code(302);
        exit;
    }

    // -------------------------------------------------------------------------
    // GET /api/v1/payments/{orderId}
    // Check current status (requires auth)
    // -------------------------------------------------------------------------
    public function status(string $orderId): void
    {
        $tenantId = $_REQUEST['_tenant_id'] ?? null;
        if (!$tenantId) {
            http_response_code(403);
            echo json_encode(['error' => 'Tenant context required']);
            return;
        }

        $stmt = $this->db->prepare('
            SELECT cart_id, telr_order_id, amount, currency, status, created_at, updated_at
            FROM payments
            WHERE telr_order_id = :order_id AND tenant_id = :tenant_id
            LIMIT 1
        ');
        $stmt->execute([':order_id' => $orderId, ':tenant_id' => $tenantId]);
        $payment = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$payment) {
            http_response_code(404);
            echo json_encode(['error' => 'Payment not found']);
            return;
        }

        echo json_encode($payment);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function decodeJsonBody(): array
    {
        $raw = file_get_contents('php://input');
        $data = json_decode($raw ?? '', true);
        if (!is_array($data)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON body']);
            exit;
        }
        return $data;
    }
}
