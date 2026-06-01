<?php

namespace App\Services;

/**
 * FunnelEventService — best-effort structured business analytics.
 *
 * Ported from Rew (realestate-saas) lib/funnel-events.ts.
 * Persists to the `funnel_events` MySQL table (migration 004).
 *
 * Design principle: errors are logged, never thrown.
 * The caller's main operation must never fail because telemetry failed.
 *
 * Known event names:
 *   inquiry_created    — new contact inquiry submitted
 *   payment_succeeded  — Telr callback: status = completed
 *   payment_failed     — Telr callback: status = failed
 *   user_registered    — new tenant user created
 */
class FunnelEventService
{
    public function __construct(private \PDO $db) {}

    /**
     * @param string               $eventName  One of the known event name constants.
     * @param string               $tenantId   Empty string for platform-level events.
     * @param array<string,mixed>  $metadata   Arbitrary key-value context.
     */
    public function track(string $eventName, string $tenantId = '', array $metadata = []): void
    {
        try {
            $stmt = $this->db->prepare(
                'INSERT INTO funnel_events (tenant_id, event_name, metadata, created_at)
                 VALUES (?, ?, ?, NOW())'
            );
            $stmt->execute([
                $tenantId !== '' ? $tenantId : null,
                $eventName,
                json_encode($metadata, JSON_UNESCAPED_UNICODE) ?: '{}',
            ]);
        } catch (\Throwable $e) {
            error_log('FunnelEventService::track error: ' . $e->getMessage());
        }
    }
}
