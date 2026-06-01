<?php
/**
 * WhatsAppService — Meta WhatsApp Cloud API integration.
 *
 * Sends templated WhatsApp notifications to agents when a new inquiry arrives.
 *
 * Environment variables required:
 *   WHATSAPP_TOKEN       — Meta permanent system user access token (Bearer)
 *   WHATSAPP_PHONE_ID    — WhatsApp Business phone number ID from Meta dashboard
 *   WHATSAPP_AGENT_NUMBERS — Comma-separated E.164 numbers to notify, e.g. "+966501234567,+971501234567"
 *   WHATSAPP_TEMPLATE_INQUIRY — Template name for new-inquiry notification (default: "new_inquiry_agent")
 */

require_once __DIR__ . '/FeatureFlags.php';

class WhatsAppService
{
    private const API_BASE = 'https://graph.facebook.com/v19.0';

    private string $token;
    private string $phoneId;
    /** @var string[] */
    private array $agentNumbers;
    private string $inquiryTemplate;

    public function __construct()
    {
        $this->token           = (string) (getenv('WHATSAPP_TOKEN')    ?: ($_ENV['WHATSAPP_TOKEN']    ?? ''));
        $this->phoneId         = (string) (getenv('WHATSAPP_PHONE_ID') ?: ($_ENV['WHATSAPP_PHONE_ID'] ?? ''));
        $rawNumbers            = (string) (getenv('WHATSAPP_AGENT_NUMBERS') ?: ($_ENV['WHATSAPP_AGENT_NUMBERS'] ?? ''));
        $this->agentNumbers    = array_filter(array_map('trim', explode(',', $rawNumbers)));
        $this->inquiryTemplate = (string) (getenv('WHATSAPP_TEMPLATE_INQUIRY') ?: ($_ENV['WHATSAPP_TEMPLATE_INQUIRY'] ?? 'new_inquiry_agent'));
    }

    /**
     * Notify all configured agent numbers about a new contact inquiry.
     *
     * The Meta template "new_inquiry_agent" must be pre-approved and must accept
     * three body parameters in order:
     *   {{1}} — Inquirer name
     *   {{2}} — Property title
     *   {{3}} — Inquirer phone or email (contact detail)
     *
     * @param array $inquiry {
     *   'name'    => string,
     *   'email'   => string,
     *   'phone'   => string|null,
     *   'message' => string,
     *   'land_title' => string,   (resolved from listings)
     * }
     *
     * @return array ['sent' => int, 'failed' => int, 'errors' => string[]]
     */
    public function notifyAgentsNewInquiry(array $inquiry): array
    {
        if (!FeatureFlags::isEnabled('WHATSAPP_NOTIFICATIONS')) {
            return ['sent' => 0, 'failed' => 0, 'errors' => ['Feature disabled']];
        }

        if ($this->token === '' || $this->phoneId === '') {
            error_log('WhatsAppService: WHATSAPP_TOKEN or WHATSAPP_PHONE_ID not configured.');
            return ['sent' => 0, 'failed' => 0, 'errors' => ['Service not configured']];
        }

        if (empty($this->agentNumbers)) {
            return ['sent' => 0, 'failed' => 0, 'errors' => ['No agent numbers configured']];
        }

        $contact = $inquiry['phone'] ?: $inquiry['email'];
        $results = ['sent' => 0, 'failed' => 0, 'errors' => []];

        foreach ($this->agentNumbers as $number) {
            $to = $this->normalizeE164($number);
            if ($to === null) {
                $results['failed']++;
                $results['errors'][] = "Invalid phone number: $number";
                continue;
            }

            $payload = [
                'messaging_product' => 'whatsapp',
                'to'                => $to,
                'type'              => 'template',
                'template'          => [
                    'name'       => $this->inquiryTemplate,
                    'language'   => ['code' => 'en_US'],
                    'components' => [
                        [
                            'type'       => 'body',
                            'parameters' => [
                                ['type' => 'text', 'text' => substr((string) $inquiry['name'], 0, 60)],
                                ['type' => 'text', 'text' => substr((string) ($inquiry['land_title'] ?? 'Unknown property'), 0, 60)],
                                ['type' => 'text', 'text' => substr((string) $contact, 0, 60)],
                            ],
                        ],
                    ],
                ],
            ];

            try {
                $this->post("//{$this->phoneId}/messages", $payload);
                $results['sent']++;
            } catch (\RuntimeException $e) {
                $results['failed']++;
                $results['errors'][] = $e->getMessage();
                error_log('WhatsAppService send error: ' . $e->getMessage());
            }
        }

        return $results;
    }

    /**
     * Send a free-form text message to a single number (utility / admin use).
     *
     * Note: Only possible within a 24-hour customer-service window.
     * For outbound-only notifications, always use templates.
     *
     * @param string $to      E.164 phone number
     * @param string $message Plain text message (max 4096 chars)
     */
    public function sendText(string $to, string $message): void
    {
        $normalized = $this->normalizeE164($to);
        if ($normalized === null) {
            throw new \InvalidArgumentException("Invalid phone number: $to");
        }

        $payload = [
            'messaging_product' => 'whatsapp',
            'to'                => $normalized,
            'type'              => 'text',
            'text'              => ['body' => substr($message, 0, 4096)],
        ];

        $this->post("//{$this->phoneId}/messages", $payload);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function post(string $path, array $payload): array
    {
        $url = self::API_BASE . $path;

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode($payload, JSON_THROW_ON_ERROR),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 15,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $this->token,
            ],
        ]);

        $body   = curl_exec($ch);
        $errno  = curl_errno($ch);
        $error  = curl_error($ch);
        $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($errno !== 0) {
            throw new \RuntimeException("cURL error ($errno): $error");
        }

        $decoded = json_decode($body, true, 512, JSON_THROW_ON_ERROR);

        if ($status >= 400) {
            $msg = $decoded['error']['message'] ?? "HTTP $status";
            throw new \RuntimeException("WhatsApp API error: $msg");
        }

        return is_array($decoded) ? $decoded : [];
    }

    /**
     * Normalize a phone number to E.164 (digits only, with leading +).
     * Returns null if the number doesn't look valid after stripping.
     */
    private function normalizeE164(string $number): ?string
    {
        $digits = preg_replace('/[^\d+]/', '', $number);

        // Already E.164 or starts with country code
        if (str_starts_with($digits, '+')) {
            $plain = ltrim($digits, '+');
        } else {
            $plain = $digits;
        }

        // Must be 7–15 digits
        if (!preg_match('/^\d{7,15}$/', $plain)) {
            return null;
        }

        return '+' . $plain;
    }
}
