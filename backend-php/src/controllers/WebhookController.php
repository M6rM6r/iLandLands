<?php

namespace App\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use App\Services\SignatureVerifier;
use App\Services\QueueStore;
use App\Services\PayTabsService;

/**
 * WebhookController — handles inbound webhook callbacks (Slim 4).
 *
 * Routes (registered in Routes.php):
 *   GET  /api/webhooks/whatsapp  — Meta verification challenge
 *   POST /api/webhooks/whatsapp  — Meta inbound messages (enqueue)
 *   POST /api/webhooks/paytabs   — PayTabs IPN callback (enqueue)
 */
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

    public function whatsappVerify(Request $request, Response $response): Response
    {
        $params    = $request->getQueryParams();
        $mode      = $params['hub_mode']         ?? '';
        $token     = $params['hub_verify_token'] ?? '';
        $challenge = $params['hub_challenge']    ?? '';

        $expectedToken = (string) (getenv('WHATSAPP_VERIFY_TOKEN') ?: '');
        if ($expectedToken === '') {
            $response->getBody()->write(json_encode(['error' => 'Webhook verify token not configured']));
            return $response->withStatus(500)->withHeader('Content-Type', 'application/json');
        }

        if ($mode === 'subscribe' && hash_equals($expectedToken, $token)) {
            $response->getBody()->write($challenge);
            return $response->withStatus(200)->withHeader('Content-Type', 'text/plain');
        }

        $response->getBody()->write(json_encode(['error' => 'Forbidden']));
        return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
    }

    public function whatsappInbound(Request $request, Response $response): Response
    {
        $rawBody   = (string) $request->getBody();
        $signature = $request->getHeaderLine('X-Hub-Signature-256');
        $appSecret = (string) (getenv('WHATSAPP_APP_SECRET') ?: '');

        if ($appSecret !== '') {
            $bareSignature = ltrim($signature, 'sha256=');
            if (!SignatureVerifier::isValid($rawBody, $bareSignature, $appSecret)) {
                $response->getBody()->write(json_encode(['error' => 'Invalid signature']));
                return $response->withStatus(403)->withHeader('Content-Type', 'application/json');
            }
        }

        $payload = json_decode($rawBody, true);
        if (!is_array($payload)) {
            $response->getBody()->write(json_encode(['error' => 'Invalid JSON payload']));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
        }

        $id = $this->whatsappQueue->enqueue([
            'source'      => 'whatsapp',
            'received_at' => gmdate('c'),
            'payload'     => $payload,
        ]);

        $response->getBody()->write(json_encode(['ok' => true, 'id' => $id]));
        return $response->withStatus(200)->withHeader('Content-Type', 'application/json');
    }

    // ── PayTabs ─────────────────────────────────────────────────────────────────

    public function paytabsCallback(Request $request, Response $response): Response
    {
        $rawBody = (string) $request->getBody();
        $payload = json_decode($rawBody, true);

        if (!is_array($payload)) {
            $parsedBody = $request->getParsedBody();
            $payload    = is_array($parsedBody) ? $parsedBody : [];
        }

        if (empty($payload)) {
            $response->getBody()->write(json_encode(['error' => 'Empty payload']));
            return $response->withStatus(400)->withHeader('Content-Type', 'application/json');
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

        $response->getBody()->write(json_encode(['ok' => true, 'id' => $id]));
        return $response->withStatus(200)->withHeader('Content-Type', 'application/json');
    }
}
