<?php
/**
 * TelrPaymentService — Slim 4 admin portal variant.
 *
 * Wraps the Telr hosted-payment-page flow for the admin/B2B portal.
 * Environment variables (same as vanilla API):
 *   TELR_STORE_ID, TELR_AUTH_KEY, TELR_TEST_MODE, APP_BASE_URL
 */

namespace App\Services;

use RuntimeException;
use InvalidArgumentException;

class TelrPaymentService
{
    private const TELR_API_URL = 'https://secure.telr.com/gateway/order.json';

    private string $storeId;
    private string $authKey;
    private bool $testMode;
    private string $baseUrl;

    public function __construct()
    {
        $this->storeId  = (string) (getenv('TELR_STORE_ID')  ?: '');
        $this->authKey  = (string) (getenv('TELR_AUTH_KEY')  ?: '');
        $this->testMode = ((getenv('TELR_TEST_MODE') ?: '1') === '1');
        $this->baseUrl  = rtrim((string) (getenv('APP_BASE_URL') ?: 'https://api.gulflands.com'), '/');

        if ($this->storeId === '' || $this->authKey === '') {
            throw new RuntimeException('TELR_STORE_ID and TELR_AUTH_KEY must be set.');
        }
    }

    /**
     * Create a Telr payment order and return the hosted-page URL.
     *
     * @param array  $order    {cart_id, amount, currency, description, customer?}
     * @param string $tenantId Tenant UUID (for callback URL scoping)
     *
     * @return array ['order_id' => string, 'payment_url' => string]
     */
    public function initiate(array $order, string $tenantId): array
    {
        $this->validateOrderPayload($order);
        $cartId = $this->sanitizeCartId((string) $order['cart_id']);

        $payload = [
            'ivp_method'     => 'create',
            'ivp_store'      => $this->storeId,
            'ivp_authkey'    => $this->authKey,
            'ivp_cart'       => $cartId,
            'ivp_amount'     => number_format((float) $order['amount'], 2, '.', ''),
            'ivp_currency'   => strtoupper((string) $order['currency']),
            'ivp_test'       => $this->testMode ? 1 : 0,
            'ivp_desc'       => substr((string) $order['description'], 0, 255),
            'return_auth'    => $this->baseUrl . '/api/v1/payments/return?status=auth&tenant_id=' . urlencode($tenantId),
            'return_decl'    => $this->baseUrl . '/api/v1/payments/return?status=decl&tenant_id=' . urlencode($tenantId),
            'return_can'     => $this->baseUrl . '/api/v1/payments/cancel?tenant_id=' . urlencode($tenantId),
            'ivp_update_url' => $this->baseUrl . '/api/v1/payments/callback',
        ];

        if (!empty($order['customer'])) {
            $customer = $order['customer'];
            $payload['bill_email']   = filter_var($customer['email']               ?? '', FILTER_SANITIZE_EMAIL);
            $payload['bill_custref'] = (string) ($customer['ref']                   ?? '');
            $payload['bill_fname']   = (string) ($customer['name']['forenames']    ?? '');
            $payload['bill_sname']   = (string) ($customer['name']['surname']      ?? '');
        }

        $response = $this->post($payload);

        if (isset($response['error']['message'])) {
            throw new RuntimeException('Telr error: ' . $response['error']['message']);
        }
        if (empty($response['order']['url'])) {
            throw new RuntimeException('Telr returned no payment URL.');
        }

        return [
            'order_id'    => $response['order']['ref'],
            'payment_url' => $response['order']['url'],
        ];
    }

    /**
     * Verify the status of an existing Telr order by reference.
     *
     * @param string $orderId Telr order reference
     *
     * @return array ['status' => string, 'code' => string, 'amount' => string, 'currency' => string]
     */
    public function verify(string $orderId): array
    {
        if ($orderId === '' || !preg_match('/^[A-Za-z0-9\-_]{1,64}$/', $orderId)) {
            throw new InvalidArgumentException('Invalid orderId format.');
        }

        $payload = [
            'ivp_method'  => 'check',
            'ivp_store'   => $this->storeId,
            'ivp_authkey' => $this->authKey,
            'ivp_cart'    => $orderId,
            'ivp_test'    => $this->testMode ? 1 : 0,
        ];

        $response = $this->post($payload);

        if (isset($response['error']['message'])) {
            throw new RuntimeException('Telr verify error: ' . $response['error']['message']);
        }

        $order = $response['order'] ?? [];
        return [
            'status'   => $order['status']['text']     ?? 'unknown',
            'code'     => (string) ($order['status']['code'] ?? ''),
            'amount'   => (string) ($order['amount']['value'] ?? ''),
            'currency' => (string) ($order['amount']['currency'] ?? ''),
        ];
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function post(array $payload): array
    {
        $ch = curl_init(self::TELR_API_URL);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query($payload),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_HTTPHEADER     => ['Accept: application/json'],
        ]);

        $body  = curl_exec($ch);
        $errno = curl_errno($ch);
        $error = curl_error($ch);
        curl_close($ch);

        if ($errno !== 0) {
            throw new RuntimeException('cURL error (' . $errno . '): ' . $error);
        }

        $decoded = json_decode($body, true, 512, JSON_THROW_ON_ERROR);
        return is_array($decoded) ? $decoded : [];
    }

    private function validateOrderPayload(array $order): void
    {
        foreach (['cart_id', 'amount', 'currency', 'description'] as $field) {
            if (empty($order[$field])) {
                throw new InvalidArgumentException("Missing required field: $field");
            }
        }

        $allowed = ['SAR', 'AED', 'QAR', 'BHD', 'KWD', 'OMR'];
        if (!in_array(strtoupper((string) $order['currency']), $allowed, true)) {
            throw new InvalidArgumentException('Currency must be one of: ' . implode(', ', $allowed));
        }

        if (!is_numeric($order['amount']) || (float) $order['amount'] <= 0) {
            throw new InvalidArgumentException('Amount must be a positive number.');
        }
    }

    private function sanitizeCartId(string $cartId): string
    {
        return substr(preg_replace('/[^A-Za-z0-9\-_]/', '', $cartId), 0, 64);
    }
}
