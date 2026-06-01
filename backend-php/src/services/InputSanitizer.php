<?php

namespace App\Services;

/**
 * InputSanitizer — XSS-safe HTML and text sanitization (Slim 4 / PSR namespace).
 *
 * @see backend/services/InputSanitizer.php for the vanilla-PHP counterpart.
 */
class InputSanitizer
{
    private const ALLOWED_TAGS = [
        'p', 'br', 'strong', 'em', 'u', 's',
        'ul', 'ol', 'li',
        'h1', 'h2', 'h3', 'h4',
        'blockquote', 'a', 'img', 'hr',
    ];

    private const ALLOWED_ATTRS = ['href', 'src', 'alt', 'title', 'target', 'rel'];

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    public static function sanitizeHtml(string $dirty): string
    {
        if ($dirty === '') {
            return '';
        }

        $tagList  = '<' . implode('><', self::ALLOWED_TAGS) . '>';
        $stripped = strip_tags($dirty, $tagList);

        return self::stripDisallowedAttributes($stripped);
    }

    public static function sanitizeText(string $input): string
    {
        if ($input === '') {
            return '';
        }

        $noTags = strip_tags($input);
        return htmlspecialchars($noTags, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }

    public static function sanitizeUrl(string $url): string
    {
        $trimmed  = trim($url);
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

        $dom = new \DOMDocument();
        @$dom->loadHTML('<?xml encoding="UTF-8"><body>' . $html . '</body>', LIBXML_HTML_NOIMPLIED | LIBXML_HTML_NODEFDTD);

        $xpath    = new \DOMXPath($dom);
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
