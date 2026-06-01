<?php

namespace App\Services;

/**
 * PayTabsService — alternative Gulf payment gateway integration (Slim 4).
 *
 * Ported from Rew (realestate-saas) lib/billing/paytabs.ts.
 * Supports SAR, AED, QAR, BHD, OMR, KWD.
 *
 * Environment variables required:
 *   PAYTABS_SERVER_KEY — API server key from PayTabs merchant dashboard
 *   PAYTABS_PROFILE_ID — Payment page profile ID
 *   PAYTABS_REGION     — SAU|UAE|QAT|BHR|OMN|KWT|EGY (default: UAE)
 *   APP_BASE_URL       — e.g. https://api.gulflands.com
 */
class PayTabsService
{
    private const REGION_ENDPOINTS = [
        'SAU' => 'https://secure.paytabs.sa/payment/request',
        'UAE' => 'https://secure.paytabs.com/payment/request',
        'QAT' => 'https://secure.paytabs.qa/payment/request',
        'BHR' => 'https://secure.paytabs.bh/payment/request',
        'OMN' => 'https://secure.paytabs.om/payment/request',
        'KWT' => 'https://secure.paytabs.kw/payment/request',
        'EGY' => 'https://secure.paytabs.eg/payment/request',
    ];

    private const CHECKOUT_KEYS = [
        'redirect_url', 'redirectUrl', 'payment_url', 'paymentUrl',
        'payment_link', 'paymentLink', 'url',
    ];

    private const VALID_STATUSES = ['paid', 'pending', 'failed', 'unpaid'];

    private string $serverKey;
    private string $profileId;
    private string $apiEndpoint;
    private string $baseUrl;

    public function __construct()
    {
        $region = strtoupper((string) ($_ENV['PAYTABS_REGION'] ?? getenv('PAYTABS_REGION') ?? 'UAE'));

        $this->serverKey   = (string) ($_ENV['PAYTABS_SERVER_KEY'] ?? getenv('PAYTABS_SERVER_KEY') ?? '');
        $this->profileId   = (string) ($_ENV['PAYTABS_PROFILE_ID'] ?? getenv('PAYTABS_PROFILE_ID') ?? '');
        $this->apiEndpoint = self::REGION_ENDPOINTS[$region] ?? self::REGION_ENDPOINTS['UAE'];
        $this->baseUrl     = rtrim((string) ($_ENV['APP_BASE_URL'] ?? getenv('APP_BASE_URL') ?? 'https://api.gulflands.com'), '/');
    }

    /**
     * @param array{
     *     cart_id: string,
     *     amount: float,
     *     currency: string,
     *     description: string,
     *     customer_name: string,
     *     customer_email: string,
     *     customer_phone?: string,
     *     country_code?: string,
     * } $params
     * @return array{success: bool, checkout_url?: string, tran_ref?: string, error?: string}
     */
    public function createCheckout(array $params): array
    {
        if (!$this->serverKey || !$this->profileId) {
            return ['success' => false, 'error' => 'PayTabs not configured'];
        }

        $payload = [
            'profile_id'       => $this->profileId,
            'tran_type'        => 'sale',
            'tran_class'       => 'ecom',
            'cart_id'          => $params['cart_id'],
            'cart_amount'      => round((float) $params['amount'], 2),
            'cart_currency'    => strtoupper($params['currency'] ?? 'AED'),
            'cart_description' => substr($params['description'] ?? 'Gulf Lands Payment', 0, 100),
            'callback'         => $this->baseUrl . '/api/payments/paytabs/callback',
            'return'           => $this->baseUrl . '/api/payments/return',
            'customer_details' => [
                'name'    => substr($params['customer_name']  ?? 'Customer', 0, 80),
                'email'   => $params['customer_email'] ?? '',
                'phone'   => $params['customer_phone'] ?? '',
                'country' => strtoupper($params['country_code'] ?? 'AE'),
            ],
        ];

        $response = $this->post($payload);
        if ($response === null) {
            return ['success' => false, 'error' => 'PayTabs API unreachable'];
        }

        $checkoutUrl = $this->extractCheckoutUrl($response);
        if ($checkoutUrl === '') {
            $msg = $response['message'] ?? $response['response_message'] ?? 'Unknown PayTabs error';
            return ['success' => false, 'error' => (string) $msg];
        }

        return [
            'success'      => true,
            'checkout_url' => $checkoutUrl,
            'tran_ref'     => (string) ($response['tran_ref'] ?? ''),
        ];
    }

    /**
     * @param array $payload  Raw decoded JSON from PayTabs webhook.
     * @return array{responseStatus:string, responseCode:string, responseMessage:string, tranRef:string, cartId:string, billingStatus:string}
     */
    public function parseCallback(array $payload): array
    {
        $result = $payload['payment_result'] ?? [];

        return [
            'responseStatus'  => trim((string) ($result['response_status']  ?? $payload['respStatus']  ?? '')),
            'responseCode'    => trim((string) ($result['response_code']    ?? $payload['respCode']    ?? '')),
            'responseMessage' => trim((string) ($result['response_message'] ?? $payload['respMessage'] ?? '')),
            'tranRef'         => trim((string) ($payload['tran_ref']        ?? $payload['tranRef']     ?? '')),
            'cartId'          => trim((string) ($payload['cart_id']         ?? $payload['cartId']      ?? '')),
            'billingStatus'   => $this->normalizeBillingStatus($result['response_status'] ?? $payload['respStatus'] ?? ''),
        ];
    }

    public function normalizeBillingStatus(mixed $value): string
    {
        $v = strtolower(trim((string) $value));
        if ($v === 'a' || $v === 'paid' || $v === 'approved') return 'paid';
        if ($v === 'h' || $v === 'pending') return 'pending';
        if ($v === 'd' || $v === 'e' || $v === 'failed' || $v === 'declined') return 'failed';
        return in_array($v, self::VALID_STATUSES, true) ? $v : 'unpaid';
    }

    private function post(array $payload): ?array
    {
        $ch = curl_init($this->apiEndpoint);
        curl_setopt_array($ch, [
            \CURLOPT_RETURNTRANSFER => true,
            \CURLOPT_TIMEOUT        => 15,
            \CURLOPT_POST           => true,
            \CURLOPT_POSTFIELDS     => json_encode($payload, \JSON_THROW_ON_ERROR),
            \CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Authorization: ' . $this->serverKey,
            ],
            \CURLOPT_SSL_VERIFYPEER => true,
        ]);

        $body  = curl_exec($ch);
        $errno = curl_errno($ch);
        curl_close($ch);

        if ($errno || !is_string($body)) {
            error_log("PayTabsService cURL error {$errno}");
            return null;
        }

        $decoded = json_decode($body, true);
        return is_array($decoded) ? $decoded : null;
    }

    private function extractCheckoutUrl(mixed $input, int $depth = 0): string
    {
        if ($depth > 4 || $input === null) return '';

        if (is_string($input)) {
            return preg_match('#^https?://#i', trim($input)) ? trim($input) : '';
        }

        if (is_array($input)) {
            foreach (self::CHECKOUT_KEYS as $key) {
                if (isset($input[$key]) && is_string($input[$key])
                    && preg_match('#^https?://#i', trim($input[$key]))) {
                    return trim($input[$key]);
                }
            }
            foreach ($input as $value) {
                $found = $this->extractCheckoutUrl($value, $depth + 1);
                if ($found !== '') return $found;
            }
        }

        return '';
    }
}
