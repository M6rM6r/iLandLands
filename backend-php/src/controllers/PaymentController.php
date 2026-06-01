<?php
/**
 * PaymentController — Slim 4 PSR-7 version.
 *
 * Routes (registered in Routes.php):
 *   POST   /api/payments/initiate          → initiate()   (auth + tenant)
 *   POST   /api/payments/callback          → callback()   (public — Telr webhook)
 *   GET    /api/payments/return            → returnRedirect()  (public)
 *   GET    /api/payments/cancel            → cancelRedirect()  (public)
 *   GET    /api/payments/{orderId}         → status()     (auth + tenant)
 */

namespace App\Controllers;

use PDO;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Services\TelrPaymentService;
use App\Services\FunnelEventService;
use RuntimeException;
use InvalidArgumentException;

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
    // POST /api/payments/initiate  (auth + tenant middleware)
    // -------------------------------------------------------------------------
    public function initiate(Request $request, Response $response): Response
    {
        $tenantId = $request->getAttribute('tenant_id');
        $admin    = $request->getAttribute('admin');

        $body = (array) ($request->getParsedBody() ?? []);

        // Build unique cart ID
        $cartId = sprintf(
            '%s-%s-%s',
            substr((string) $tenantId, 0, 8),
            date('YmdHis'),
            bin2hex(random_bytes(4))
        );

        // Persist pending record
        $stmt = $this->db->prepare('
            INSERT INTO payments (cart_id, tenant_id, user_id, listing_id, amount, currency, status, created_at)
            VALUES (:cart_id, :tenant_id, :user_id, :listing_id, :amount, :currency, "pending", NOW())
        ');
        $stmt->execute([
            ':cart_id'    => $cartId,
            ':tenant_id'  => $tenantId,
            ':user_id'    => $admin->id ?? null,
            ':listing_id' => $body['listing_id'] ?? null,
            ':amount'     => $body['amount'] ?? 0,
            ':currency'   => strtoupper((string) ($body['currency'] ?? 'AED')),
        ]);

        try {
            $result = $this->telr->initiate([
                'cart_id'     => $cartId,
                'amount'      => $body['amount'] ?? 0,
                'currency'    => strtoupper((string) ($body['currency'] ?? 'AED')),
                'description' => $body['description'] ?? 'Gulflands admin payment',
                'customer'    => $body['customer'] ?? [],
            ], (string) $tenantId);

            // Store Telr reference
            $this->db->prepare('UPDATE payments SET telr_order_id = :ref WHERE cart_id = :cart_id')
                ->execute([':ref' => $result['order_id'], ':cart_id' => $cartId]);

            $response->getBody()->write(json_encode([
                'cart_id'     => $cartId,
                'order_id'    => $result['order_id'],
                'payment_url' => $result['payment_url'],
            ]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(201);
        } catch (InvalidArgumentException $e) {
            $response->getBody()->write(json_encode(['error' => $e->getMessage()]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(422);
        } catch (RuntimeException $e) {
            error_log('Telr initiate error: ' . $e->getMessage());
            $response->getBody()->write(json_encode(['error' => 'Payment gateway unavailable']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(502);
        }
    }

    // -------------------------------------------------------------------------
    // POST /api/payments/callback  (public — Telr server-to-server webhook)
    // -------------------------------------------------------------------------
    public function callback(Request $request, Response $response): Response
    {
        $params  = (array) ($request->getParsedBody() ?? []);
        $cartId  = $params['cart_id']  ?? '';
        $orderId = $params['order_id'] ?? '';

        if ($cartId === '' || $orderId === '') {
            $response->getBody()->write(json_encode(['error' => 'Missing cart_id or order_id']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(400);
        }

        try {
            $verified   = $this->telr->verify($orderId);
            $statusCode = $verified['code'];

            $mappedStatus = match (true) {
                $statusCode === '3'                        => 'completed',
                in_array($statusCode, ['2', '6'], true)   => 'failed',
                default                                    => 'pending',
            };

            $this->db->prepare('
                UPDATE payments
                SET status = :status, telr_order_id = :order_id, updated_at = NOW()
                WHERE cart_id = :cart_id
            ')->execute([
                ':status'   => $mappedStatus,
                ':order_id' => $orderId,
                ':cart_id'  => $cartId,
            ]);

            // Funnel event — best effort
            $funnelEvent = $mappedStatus === 'completed' ? 'payment_succeeded' : ($mappedStatus === 'failed' ? 'payment_failed' : null);
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

            $response->getBody()->write(json_encode(['received' => true]));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(200);
        } catch (RuntimeException $e) {
            error_log('Telr callback verify error: ' . $e->getMessage());
            $response->getBody()->write(json_encode(['error' => 'Verification failed']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(502);
        }
    }

    // -------------------------------------------------------------------------
    // GET /api/payments/return  (public — browser redirect)
    // -------------------------------------------------------------------------
    public function returnRedirect(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        $status = $params['status'] ?? 'unknown';

        $appUrl        = rtrim((string) (getenv('APP_FRONTEND_URL') ?: 'https://app.gulflands.com'), '/');
        $redirectStatus = ($status === 'auth') ? 'success' : 'declined';

        return $response->withHeader('Location', $appUrl . '/payment/' . $redirectStatus)->withStatus(302);
    }

    // -------------------------------------------------------------------------
    // GET /api/payments/cancel  (public — browser redirect)
    // -------------------------------------------------------------------------
    public function cancelRedirect(Request $request, Response $response): Response
    {
        $appUrl = rtrim((string) (getenv('APP_FRONTEND_URL') ?: 'https://app.gulflands.com'), '/');

        return $response->withHeader('Location', $appUrl . '/payment/cancelled')->withStatus(302);
    }

    // -------------------------------------------------------------------------
    // GET /api/payments/{orderId}  (auth + tenant middleware)
    // -------------------------------------------------------------------------
    public function status(Request $request, Response $response, array $args): Response
    {
        $orderId  = $args['orderId'] ?? '';
        $tenantId = $request->getAttribute('tenant_id');

        $stmt = $this->db->prepare('
            SELECT cart_id, telr_order_id, amount, currency, status, created_at, updated_at
            FROM payments
            WHERE telr_order_id = :order_id AND tenant_id = :tenant_id
            LIMIT 1
        ');
        $stmt->execute([':order_id' => $orderId, ':tenant_id' => $tenantId]);
        $payment = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$payment) {
            $response->getBody()->write(json_encode(['error' => 'Payment not found']));
            return $response->withHeader('Content-Type', 'application/json')->withStatus(404);
        }

        $response->getBody()->write(json_encode($payment));
        return $response->withHeader('Content-Type', 'application/json');
    }
}
