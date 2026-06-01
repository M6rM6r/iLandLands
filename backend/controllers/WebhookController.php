<?php
/**
 * WebhookController — handles inbound webhook callbacks.
 *
 * Currently supports:
 *   POST /api/v1/webhooks/whatsapp  — Meta WhatsApp Cloud API inbound messages
 *   GET  /api/v1/webhooks/whatsapp  — Meta webhook verification challenge
 *
 *   POST /api/v1/webhooks/paytabs   — PayTabs IPN callback
 */

require_once __DIR__ . '/../services/SignatureVerifier.php';
require_once __DIR__ . '/../services/QueueStore.php';
require_once __DIR__ . '/../services/PayTabsService.php';
require_once __DIR__ . '/../config/database.php';

class WebhookController
{
    private QueueStore $whatsappQueue;
    private QueueStore $paytabsQueue;

    public function __construct()
    {
        $queueBase = rtrim((string) (getenv('QUEUE_DIR') ?: '/var/data/queues'), '/');
        $this->whatsappQueue = new QueueStore(
            queueDir:      $queueBase . '/whatsapp',
            deadLetterDir: $queueBase . '/whatsapp-dlq',
        );
        $this->paytabsQueue = new QueueStore(
            queueDir:      $queueBase . '/paytabs',
            deadLetterDir: $queueBase . '/paytabs-dlq',
        );
    }

    // ── WhatsApp ────────────────────────────────────────────────────────────────

    /**
     * GET /api/v1/webhooks/whatsapp — Meta webhook verification challenge.
     */
    public function whatsappVerify(): void
    {
        $mode      = $_GET['hub_mode']          ?? '';
        $token     = $_GET['hub_verify_token']  ?? '';
        $challenge = $_GET['hub_challenge']     ?? '';

        $expectedToken = (string) (getenv('WHATSAPP_VERIFY_TOKEN') ?: '');
        if ($expectedToken === '') {
            http_response_code(500);
            echo json_encode(['error' => 'Webhook verify token not configured']);
            return;
        }

        if ($mode === 'subscribe' && hash_equals($expectedToken, $token)) {
            http_response_code(200);
            header('Content-Type: text/plain');
            echo $challenge;
            return;
        }

        http_response_code(403);
        echo json_encode(['error' => 'Forbidden']);
    }

    /**
     * POST /api/v1/webhooks/whatsapp — receive inbound WhatsApp messages.
     *
     * Validates the X-Hub-Signature-256 header, then immediately enqueues
     * the event and returns 200 OK (Meta requires <5s response time).
     */
    public function whatsappInbound(): void
    {
        $rawBody   = (string) file_get_contents('php://input');
        $signature = $_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '';
        $appSecret = (string) (getenv('WHATSAPP_APP_SECRET') ?: '');

        // Validate signature when a secret is configured
        // X-Hub-Signature-256 header format: "sha256=<hex>" — strip prefix before compare
        if ($appSecret !== '') {
            $bareSignature = ltrim($signature, 'sha256=');
            if (!SignatureVerifier::isValid($rawBody, $bareSignature, $appSecret)) {
                http_response_code(403);
                echo json_encode(['error' => 'Invalid signature']);
                return;
            }
        }

        $payload = json_decode($rawBody, true);
        if (!is_array($payload)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON payload']);
            return;
        }

        $id = $this->whatsappQueue->enqueue([
            'source'     => 'whatsapp',
            'received_at' => gmdate('c'),
            'payload'    => $payload,
        ]);

        http_response_code(200);
        echo json_encode(['ok' => true, 'id' => $id]);
    }

    // ── PayTabs ─────────────────────────────────────────────────────────────────

    /**
     * POST /api/v1/webhooks/paytabs — PayTabs IPN callback.
     *
     * PayTabs sends a signed POST with payment_result data.
     * We enqueue immediately and return 200.
     */
    public function paytabsCallback(): void
    {
        $rawBody = (string) file_get_contents('php://input');
        $payload = json_decode($rawBody, true);

        if (!is_array($payload)) {
            // PayTabs can also send form-encoded data
            $payload = $_POST;
        }

        if (empty($payload)) {
            http_response_code(400);
            echo json_encode(['error' => 'Empty payload']);
            return;
        }

        $pt     = new PayTabsService();
        $parsed = $pt->parseCallback($payload);

        $id = $this->paytabsQueue->enqueue([
            'source'         => 'paytabs',
            'received_at'    => gmdate('c'),
            'billing_status' => $parsed['billingStatus'],
            'tran_ref'       => $parsed['tranRef'],
            'cart_id'        => $parsed['cartId'],
            'payload'        => $payload,
        ]);

        http_response_code(200);
        echo json_encode(['ok' => true, 'id' => $id]);
    }
}
