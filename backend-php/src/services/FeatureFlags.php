<?php

namespace App\Services;

/**
 * FeatureFlags — env-var-based feature toggles.
 *
 * Ported from Rew (realestate-saas) lib/feature-flags.ts.
 *
 * Usage:
 *   if (FeatureFlags::isEnabled('ADVANCED_OBSERVABILITY')) { ... }
 *
 * Override at runtime with env var FEATURE_<NAME>=true|false.
 * Per-tenant overrides can be stored in tenants.settings JSON column
 * and passed to isTenantEnabled().
 */
class FeatureFlags
{
    private const DEFAULTS = [
        'PYTHON_INTELLIGENCE'    => false,
        'PHP_WEBHOOK_GATEWAY'    => false,
        'ADVANCED_OBSERVABILITY' => true,
        'AI_DESCRIPTIONS'        => true,
        'LEAD_SCORING'           => true,
        'WHATSAPP_NOTIFICATIONS' => true,
        'HUBSPOT_SYNC'           => true,
        'PAYMENTS'               => true,
    ];

    public static function isEnabled(string $flag): bool
    {
        $envKey = 'FEATURE_' . strtoupper($flag);
        $envVal = getenv($envKey);

        if ($envVal === 'true')  return true;
        if ($envVal === 'false') return false;

        return self::DEFAULTS[strtoupper($flag)] ?? false;
    }

    /**
     * @param string     $flag
     * @param array|null $tenantSettings  Decoded tenants.settings JSON column.
     */
    public static function isTenantEnabled(string $flag, ?array $tenantSettings): bool
    {
        $key = 'feature_' . strtolower($flag);
        if ($tenantSettings !== null && isset($tenantSettings[$key])) {
            return (bool) $tenantSettings[$key];
        }
        return self::isEnabled($flag);
    }
}
