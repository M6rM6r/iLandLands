<?php
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
    /**
     * Compile-time defaults.
     * Set FEATURE_<FLAG>=true|false in the environment to override.
     */
    private const DEFAULTS = [
        // Enable Python recommendation / intelligence service calls
        'PYTHON_INTELLIGENCE'    => false,
        // Route webhook processing through the PHP webhook gateway
        'PHP_WEBHOOK_GATEWAY'    => false,
        // Emit JSON-structured logs via RequestLogger
        'ADVANCED_OBSERVABILITY' => true,
        // AI property description generation (OpenAI)
        'AI_DESCRIPTIONS'        => true,
        // Lead scoring on inquiry submission
        'LEAD_SCORING'           => true,
        // WhatsApp agent notifications
        'WHATSAPP_NOTIFICATIONS' => true,
        // HubSpot CRM sync
        'HUBSPOT_SYNC'           => true,
        // Telr payment initiation
        'PAYMENTS'               => true,
    ];

    /**
     * Check if a flag is enabled via env var, falling back to compile-time default.
     */
    public static function isEnabled(string $flag): bool
    {
        $envKey = 'FEATURE_' . strtoupper($flag);
        $envVal = getenv($envKey);

        if ($envVal === 'true')  return true;
        if ($envVal === 'false') return false;

        return self::DEFAULTS[strtoupper($flag)] ?? false;
    }

    /**
     * Check a flag with optional per-tenant JSON override.
     *
     * @param string       $flag
     * @param array|null   $tenantSettings  Decoded tenants.settings JSON column.
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
