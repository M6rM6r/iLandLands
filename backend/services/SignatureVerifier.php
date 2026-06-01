<?php
/**
 * SignatureVerifier — constant-time HMAC-SHA256 webhook signature check.
 *
 * Ported from Rew (realestate-saas) services/php-webhooks/src/Signature.php.
 *
 * Usage (WhatsApp Cloud API X-Hub-Signature-256):
 *   $sig = ltrim($_SERVER['HTTP_X_HUB_SIGNATURE_256'] ?? '', 'sha256=');
 *   if (!SignatureVerifier::isValid($rawBody, $sig, getenv('WHATSAPP_APP_SECRET'))) {
 *       http_response_code(401); exit;
 *   }
 *
 * Usage (generic HMAC webhook):
 *   $sig = $_SERVER['HTTP_X_SIGNATURE'] ?? '';
 *   SignatureVerifier::isValid(file_get_contents('php://input'), $sig, $secret);
 */
class SignatureVerifier
{
    /**
     * Returns true only when the HMAC-SHA256 of $payload with $secret
     * matches $signature using a constant-time comparison (no timing attacks).
     */
    public static function isValid(string $payload, ?string $signature, string $secret): bool
    {
        if ($signature === null || $signature === '' || $secret === '') {
            return false;
        }

        $expected = hash_hmac('sha256', $payload, $secret);
        return hash_equals($expected, $signature);
    }
}
