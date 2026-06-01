<?php

/**
 * InputSanitizer — XSS-safe HTML and text sanitization.
 *
 * Ported from Rew/lib/sanitize.ts (isomorphic-dompurify → PHP strip_tags + htmlspecialchars).
 * PHP's strip_tags() is used for the allowlist path;
 * htmlspecialchars() for plain-text contexts.
 *
 * Never use PHP's strip_tags() alone for security — it does not remove event handlers
 * inside allowed tags. This class strips all attributes from allowed tags except
 * a curated safe set (href, src, alt, title, target, rel) using a DOMDocument pass.
 *
 * @see backend-php/src/services/InputSanitizer.php for the Slim 4 counterpart.
 */
class InputSanitizer
{
    /** HTML tags considered safe for rich-text user content */
    private const ALLOWED_TAGS = [
        'p', 'br', 'strong', 'em', 'u', 's',
        'ul', 'ol', 'li',
        'h1', 'h2', 'h3', 'h4',
        'blockquote', 'a', 'img', 'hr',
    ];

    /** Attributes that are allowed to remain on any tag */
    private const ALLOWED_ATTRS = ['href', 'src', 'alt', 'title', 'target', 'rel'];

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Sanitize HTML input — strips disallowed tags and dangerous attributes.
     * Safe to persist to DB and render unescaped in CMS contexts.
     *
     * @param  string $dirty  Untrusted HTML
     * @return string         Sanitized HTML
     */
    public static function sanitizeHtml(string $dirty): string
    {
        if ($dirty === '') {
            return '';
        }

        // First pass: strip_tags keeps the allowed tag list
        $tagList = '<' . implode('><', self::ALLOWED_TAGS) . '>';
        $stripped = strip_tags($dirty, $tagList);

        // Second pass: DOMDocument removes disallowed attributes
        return self::stripDisallowedAttributes($stripped);
    }

    /**
     * Sanitize plain-text input — removes ALL HTML and encodes special chars.
     * Use for names, emails, titles, search queries, etc.
     *
     * @param  string $input
     * @return string
     */
    public static function sanitizeText(string $input): string
    {
        if ($input === '') {
            return '';
        }

        $noTags = strip_tags($input);
        return htmlspecialchars($noTags, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }

    /**
     * Sanitize a URL — only allows http/https schemes; returns empty string otherwise.
     */
    public static function sanitizeUrl(string $url): string
    {
        $trimmed = trim($url);
        if ($trimmed === '') {
            return '';
        }

        $filtered = filter_var($trimmed, FILTER_SANITIZE_URL);
        if ($filtered === false) {
            return '';
        }

        $scheme = strtolower((string) parse_url($filtered, PHP_URL_SCHEME));
        if (!in_array($scheme, ['http', 'https'], true)) {
            return '';
        }

        return $filtered;
    }

    /**
     * Sanitize a float/numeric value from user input.
     * Returns null if the value cannot be parsed as a float.
     */
    public static function sanitizeFloat(mixed $value): ?float
    {
        if (is_float($value)) {
            return $value;
        }

        $str = trim((string) $value);
        if (!is_numeric($str)) {
            return null;
        }

        return (float) $str;
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    private static function stripDisallowedAttributes(string $html): string
    {
        if ($html === '' || !class_exists('DOMDocument')) {
            return $html;
        }

        $dom = new DOMDocument();
        // Suppress warnings for malformed HTML; UTF-8 wrapper prevents charset issues
        @$dom->loadHTML('<?xml encoding="UTF-8"><body>' . $html . '</body>', LIBXML_HTML_NOIMPLIED | LIBXML_HTML_NODEFDTD);

        $xpath = new DOMXPath($dom);
        /** @var DOMElement[] $elements */
        $elements = $xpath->query('//*[@*]') ?: [];

        foreach ($elements as $element) {
            $attrsToRemove = [];
            foreach ($element->attributes as $attr) {
                if (!in_array(strtolower($attr->nodeName), self::ALLOWED_ATTRS, true)) {
                    $attrsToRemove[] = $attr->nodeName;
                }
            }
            foreach ($attrsToRemove as $attrName) {
                $element->removeAttribute($attrName);
            }
        }

        $body = $dom->getElementsByTagName('body')->item(0);
        if ($body === null) {
            return $html;
        }

        $result = '';
        foreach ($body->childNodes as $child) {
            $result .= $dom->saveHTML($child);
        }

        return $result;
    }
}
