<?php

namespace App\Services;

/**
 * WhatsAppLinkHelper — phone normalisation and wa.me link builder (Slim 4).
 *
 * Ported from Rew (realestate-saas) lib/whatsapp.ts.
 */
class WhatsAppLinkHelper
{
    private const MIN_DIGITS = 8;

    public static function buildLink(?string $input, ?string $message = null): string
    {
        $number = self::normalize($input);
        if ($number === null) {
            return '#';
        }
        if ($message === null || $message === '') {
            return "https://wa.me/{$number}";
        }
        return 'https://wa.me/' . $number . '?text=' . rawurlencode($message);
    }

    public static function normalize(?string $input): ?string
    {
        if ($input === null || trim($input) === '') {
            return null;
        }
        $raw = trim($input);

        if (preg_match('#wa\.me/([^/?#\s]+)#i', $raw, $m)) {
            $digits = preg_replace('/\D/', '', $m[1]);
            return strlen($digits) >= self::MIN_DIGITS ? $digits : null;
        }

        if (preg_match('#(?:api\.)?whatsapp\.com/send\?([^\s#]+)#i', $raw, $m)) {
            parse_str($m[1], $params);
            $digits = preg_replace('/\D/', '', $params['phone'] ?? '');
            return strlen($digits) >= self::MIN_DIGITS ? $digits : null;
        }

        $digits = preg_replace('/\D/', '', $raw);
        return strlen($digits) >= self::MIN_DIGITS ? $digits : null;
    }
}
