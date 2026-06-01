<?php
/**
 * WhatsAppLinkHelper — phone normalisation and wa.me link builder.
 *
 * Ported from Rew (realestate-saas) lib/whatsapp.ts.
 *
 * Usage:
 *   $link = WhatsAppLinkHelper::buildLink('+971 50 123 4567', 'Hello, I am interested');
 *   // => 'https://wa.me/971501234567?text=Hello%2C+I+am+interested'
 *
 *   $link = WhatsAppLinkHelper::buildLink('https://wa.me/971501234567');
 *   // => 'https://wa.me/971501234567'
 *
 *   $link = WhatsAppLinkHelper::buildLink('garbage');
 *   // => '#'
 */
class WhatsAppLinkHelper
{
    private const MIN_DIGITS = 8;

    // ── Public API ─────────────────────────────────────────────────────────────

    /**
     * Produce a wa.me deep-link from any phone representation.
     *
     * @param string|null $input    wa.me URL, whatsapp.com/send URL, or raw phone number.
     * @param string|null $message  Optional pre-filled message text (will be URL-encoded).
     * @return string  wa.me URL, or '#' if the input cannot be normalised.
     */
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

    /**
     * Normalise any phone representation to a digit-only E.164 string.
     *
     * @param string|null $input
     * @return string|null  Digit-only number, or null if un-parseable.
     */
    public static function normalize(?string $input): ?string
    {
        if ($input === null || trim($input) === '') {
            return null;
        }
        $raw = trim($input);

        // wa.me/NUMBER — extract the path segment
        if (preg_match('#wa\.me/([^/?#\s]+)#i', $raw, $m)) {
            $digits = preg_replace('/\D/', '', $m[1]);
            return strlen($digits) >= self::MIN_DIGITS ? $digits : null;
        }

        // whatsapp.com/send?phone=NUMBER
        if (preg_match('#(?:api\.)?whatsapp\.com/send\?([^\s#]+)#i', $raw, $m)) {
            parse_str($m[1], $params);
            $digits = preg_replace('/\D/', '', $params['phone'] ?? '');
            return strlen($digits) >= self::MIN_DIGITS ? $digits : null;
        }

        // Raw phone number (spaces, +, dashes, parens stripped)
        $digits = preg_replace('/\D/', '', $raw);
        return strlen($digits) >= self::MIN_DIGITS ? $digits : null;
    }
}
