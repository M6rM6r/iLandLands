<?php

/**
 * OpenAI Chat Completions service — vanilla PHP (no namespace).
 *
 * Generates bilingual (Arabic / English) professional property descriptions
 * for Gulf land listings.  Results are cached in `system_settings` using the
 * composite key  tenant_id + "property_desc_{listing_id}"  so each description
 * is generated only once per listing per tenant.
 *
 * Environment variables
 * ─────────────────────
 *  OPENAI_API_KEY   – required, OpenAI secret key (sk-…)
 */
require_once __DIR__ . '/FeatureFlags.php';

class OpenAiService
{
    private const API_URL = 'https://api.openai.com/v1/chat/completions';
    private const MODEL   = 'gpt-4o-mini';
    private const TIMEOUT = 30; // seconds

    private string $apiKey;
    private PDO    $db;

    public function __construct(PDO $db)
    {
        $this->db     = $db;
        $this->apiKey = (string) getenv('OPENAI_API_KEY');
    }

    // ──────────────────────────────────────────────────────────────
    // Public API
    // ──────────────────────────────────────────────────────────────

    /**
     * Return a professional bilingual description for a land listing.
     * Checks the cache first; calls OpenAI only on a miss.
     *
     * @param  array  $listing  Row from land_listings (must include id, tenant_id,
     *                          title, area, price, country, location)
     * @return string           Generated description, or '' on failure
     */
    public function generatePropertyDescription(array $listing): string
    {
        if (!FeatureFlags::isEnabled('AI_DESCRIPTIONS')) {
            return '';
        }

        if (empty($this->apiKey)) {
            error_log('[OpenAiService] OPENAI_API_KEY is not set');
            return '';
        }

        $tenantId  = $listing['tenant_id'] ?? '';
        $listingId = $listing['id']        ?? '';

        if ($tenantId === '' || $listingId === '') {
            error_log('[OpenAiService] generatePropertyDescription: missing tenant_id or listing id');
            return '';
        }

        $cacheKey = 'property_desc_' . $listingId;

        // 1. Cache hit
        $cached = $this->getCached($tenantId, $cacheKey);
        if ($cached !== null) {
            return $cached;
        }

        // 2. Build prompt
        $prompt = $this->buildPrompt($listing);

        // 3. Call OpenAI
        $description = $this->complete($prompt);
        if ($description === '') {
            return '';
        }

        // 4. Persist to cache
        $this->saveCache($tenantId, $cacheKey, $description);

        return $description;
    }

    /**
     * Explicitly invalidate the cached description for a listing
     * (call after a listing is updated).
     */
    public function invalidateCache(string $tenantId, string $listingId): void
    {
        $cacheKey = 'property_desc_' . $listingId;
        $stmt = $this->db->prepare(
            'DELETE FROM system_settings WHERE tenant_id = ? AND setting_key = ?'
        );
        $stmt->execute([$tenantId, $cacheKey]);
    }

    // ──────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────

    private function buildPrompt(array $listing): string
    {
        $title    = $listing['title']    ?? 'Land Plot';
        $area     = $listing['area']     ?? '';
        $price    = $listing['price']    ?? '';
        $country  = $listing['country']  ?? '';
        $location = $listing['location'] ?? '';
        $type     = $listing['type']     ?? '';

        $countryLabel = $this->countryLabel($country);
        $areaFormatted  = $area  !== '' ? number_format((float) $area, 0)  . ' m²' : 'N/A';
        $priceFormatted = $price !== '' ? number_format((float) $price, 0) . ' ' . $this->currencyCode($country) : 'N/A';

        return <<<PROMPT
You are a professional real estate copywriter specialising in Gulf region land sales.

Write a compelling property listing description for the following land plot.
Return the description in TWO sections:
  [EN] English description (3–4 sentences, professional tone)
  [AR] Arabic description (same content, formal Gulf Arabic, right-to-left)

Property details:
- Title:    {$title}
- Location: {$location}, {$countryLabel}
- Type:     {$type}
- Area:     {$areaFormatted}
- Price:    {$priceFormatted}

Do not include the price in the description text itself.
Keep each section under 120 words.
PROMPT;
    }

    private function complete(string $prompt): string
    {
        $payload = json_encode([
            'model'      => self::MODEL,
            'messages'   => [
                ['role' => 'system', 'content' => 'You are a Gulf real estate copywriter.'],
                ['role' => 'user',   'content' => $prompt],
            ],
            'max_tokens'  => 400,
            'temperature' => 0.7,
        ]);

        $ch = curl_init(self::API_URL);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $this->apiKey,
            ],
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_TIMEOUT        => self::TIMEOUT,
        ]);

        $raw  = curl_exec($ch);
        $err  = curl_error($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($err !== '') {
            error_log('[OpenAiService] cURL error: ' . $err);
            return '';
        }

        if ($code !== 200) {
            error_log('[OpenAiService] HTTP ' . $code . ': ' . substr((string) $raw, 0, 300));
            return '';
        }

        $data = json_decode((string) $raw, true);
        return trim($data['choices'][0]['message']['content'] ?? '');
    }

    private function getCached(string $tenantId, string $cacheKey): ?string
    {
        $stmt = $this->db->prepare(
            'SELECT setting_value FROM system_settings
              WHERE tenant_id = ? AND setting_key = ?
              LIMIT 1'
        );
        $stmt->execute([$tenantId, $cacheKey]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return ($row !== false) ? (string) $row['setting_value'] : null;
    }

    private function saveCache(string $tenantId, string $cacheKey, string $value): void
    {
        $stmt = $this->db->prepare(
            'INSERT INTO system_settings (tenant_id, setting_key, setting_value, description)
                  VALUES (?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                  setting_value = VALUES(setting_value),
                  updated_at    = CURRENT_TIMESTAMP'
        );
        $stmt->execute([$tenantId, $cacheKey, $value, 'AI-generated property description']);
    }

    private function countryLabel(string $country): string
    {
        return [
            'saudiArabia' => 'Saudi Arabia',
            'uae'         => 'UAE',
            'qatar'       => 'Qatar',
            'kuwait'      => 'Kuwait',
            'bahrain'     => 'Bahrain',
            'oman'        => 'Oman',
        ][$country] ?? $country;
    }

    private function currencyCode(string $country): string
    {
        return [
            'saudiArabia' => 'SAR',
            'uae'         => 'AED',
            'qatar'       => 'QAR',
            'kuwait'      => 'KWD',
            'bahrain'     => 'BHD',
            'oman'        => 'OMR',
        ][$country] ?? '';
    }
}
