<?php

namespace App\Services;

/**
 * SubscriptionService — tenant trial & billing state (Slim 4).
 *
 * Ported from Rew (realestate-saas) lib/billing/subscription.ts.
 *
 * Reads the three columns added to `tenants` in migration 005:
 *   trial_started_at, trial_expires_at, billing_status
 */
class SubscriptionService
{
    public function __construct(private \PDO $db) {}

    /**
     * @param array $tenant  Row from `tenants` table.
     * @return array{
     *     isTrialActive: bool,
     *     isTrialExpired: bool,
     *     daysLeft: int,
     *     expiresAt: string|null,
     *     billingStatus: string,
     * }
     */
    public function getTrialState(array $tenant): array
    {
        $now           = time();
        $expiresAt     = $tenant['trial_expires_at'] ?? null;
        $billingStatus = $tenant['billing_status']   ?? 'unpaid';
        $expiresTs     = $expiresAt ? strtotime($expiresAt) : null;

        $isTrialActive  = ($expiresTs !== null) && ($now < $expiresTs);
        $isTrialExpired = ($expiresTs !== null) && ($now >= $expiresTs);
        $daysLeft       = ($isTrialActive && $expiresTs !== null)
            ? max(0, (int) ceil(($expiresTs - $now) / 86400))
            : 0;

        return [
            'isTrialActive'  => $isTrialActive,
            'isTrialExpired' => $isTrialExpired,
            'daysLeft'       => $daysLeft,
            'expiresAt'      => $expiresAt,
            'billingStatus'  => $billingStatus,
        ];
    }

    public function hasAccess(array $tenant): bool
    {
        $state = $this->getTrialState($tenant);
        return $state['isTrialActive'] || $state['billingStatus'] === 'paid';
    }

    public function startTrial(string $tenantId, int $trialDays = 14): void
    {
        $stmt = $this->db->prepare(
            'UPDATE tenants
             SET trial_started_at = NOW(),
                 trial_expires_at = DATE_ADD(NOW(), INTERVAL ? DAY),
                 billing_status   = CASE WHEN billing_status = \'paid\' THEN \'paid\' ELSE \'pending\' END
             WHERE id = ?'
        );
        $stmt->execute([$trialDays, $tenantId]);
    }

    public function getTrialStateById(string $tenantId): ?array
    {
        $stmt = $this->db->prepare(
            'SELECT id, plan, billing_status, trial_started_at, trial_expires_at
             FROM tenants WHERE id = ? LIMIT 1'
        );
        $stmt->execute([$tenantId]);
        $tenant = $stmt->fetch(\PDO::FETCH_ASSOC);
        if (!$tenant) return null;
        return $this->getTrialState($tenant);
    }
}
