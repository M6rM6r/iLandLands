<?php

namespace App\Services;

/**
 * LeadScoringService — deterministic 0-100 lead score.
 *
 * Ported from the TypeScript lead-scoring engine in Rew (realestate-saas).
 * Fully synchronous, no I/O, safe to call inline on every inquiry.
 *
 * Score bands:
 *   80-100  hot  — Act within 1 hour
 *   55-79   warm — Follow up same day
 *   30-54   cold — Add to nurture sequence
 *   0-29    low  — Archive after 7 days if no response
 */
class LeadScoringService
{
    /** Scoring weights — kept identical to Rew for cross-platform consistency. */
    private const W = [
        'hasListingId'      => 20,
        'hasEmail'          => 10,
        'meaningfulMsg'     => 15,
        'detailedMsg'       => 10,
        'priceMention'      => 15,
        'urgencyKeywords'   => 10,
        'contactRequest'    =>  8,
        'internationalPhone'=>  7,
        'businessHours'     =>  5,
    ];

    /**
     * Score a lead from inquiry data.
     *
     * @param array{
     *   name: string,
     *   phone: string,
     *   email?: string,
     *   message?: string,
     *   land_id?: string,
     *   created_at?: string,
     * } $input
     * @return array{ score: int, band: string, signals: array, reasoning: string[] }
     */
    public function score(array $input): array
    {
        $signals   = [];
        $reasoning = [];

        $msg   = trim($input['message'] ?? '');
        $phone = trim($input['phone']   ?? '');
        $ts    = isset($input['created_at'])
            ? (int) strtotime((string) $input['created_at'])
            : time();

        if (!empty($input['land_id'])) {
            $signals['hasListingId'] = self::W['hasListingId'];
            $reasoning[] = 'Attached to a specific listing (+20)';
        }

        if (!empty($input['email'])) {
            $signals['hasEmail'] = self::W['hasEmail'];
            $reasoning[] = 'Provided email (+10)';
        }

        if (mb_strlen($msg) >= 30) {
            $signals['meaningfulMsg'] = self::W['meaningfulMsg'];
            $reasoning[] = 'Message ≥30 chars (+15)';
        }

        if (mb_strlen($msg) >= 80) {
            $signals['detailedMsg'] = self::W['detailedMsg'];
            $reasoning[] = 'Message ≥80 chars (+10)';
        }

        if ($msg !== '' && preg_match('/\b(price|cost|budget|سعر|ميزانية|تكلفة|\d{4,})\b/ui', $msg)) {
            $signals['priceMention'] = self::W['priceMention'];
            $reasoning[] = 'Mentions price/budget (+15)';
        }

        if ($msg !== '' && preg_match('/\b(urgent|asap|now|today|الآن|عاجل|اليوم|قريبا|soon)\b/ui', $msg)) {
            $signals['urgencyKeywords'] = self::W['urgencyKeywords'];
            $reasoning[] = 'Urgency keyword detected (+10)';
        }

        if ($msg !== '' && preg_match('/\b(call|whatsapp|contact|reach|تواصل|اتصل|واتساب)\b/ui', $msg)) {
            $signals['contactRequest'] = self::W['contactRequest'];
            $reasoning[] = 'Contact request keyword (+8)';
        }

        if ($phone !== '' && $phone[0] === '+') {
            $signals['internationalPhone'] = self::W['internationalPhone'];
            $reasoning[] = 'International phone number (+7)';
        }

        // Business hours: 08:00–20:00 GST (UTC+3)
        $gstHour = ((int) gmdate('G', $ts) + 3) % 24;
        if ($gstHour >= 8 && $gstHour < 20) {
            $signals['businessHours'] = self::W['businessHours'];
            $reasoning[] = 'Submitted during business hours (+5)';
        }

        $score = min(100, (int) array_sum($signals));

        return [
            'score'     => $score,
            'band'      => $this->band($score),
            'signals'   => $signals,
            'reasoning' => $reasoning,
        ];
    }

    private function band(int $score): string
    {
        if ($score >= 80) return 'hot';
        if ($score >= 55) return 'warm';
        if ($score >= 30) return 'cold';
        return 'low';
    }
}
