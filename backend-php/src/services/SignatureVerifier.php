<?php

namespace App\Services;

/**
 * SignatureVerifier — constant-time HMAC-SHA256 webhook signature check.
 *
 * Ported from Rew (realestate-saas) services/php-webhooks/src/Signature.php.
 *
 * Usage (WhatsApp Cloud API X-Hub-Signature-256):
 *   $sig = ltrim($request->getHeaderLine('X-Hub-Signature-256'), 'sha256=');
 *   if (!SignatureVerifier::isValid($rawBody, $sig, getenv('WHATSAPP_APP_SECRET'))) {
 *       return $response->withStatus(401);
 *   }
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
