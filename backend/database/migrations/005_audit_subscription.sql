-- ============================================================
-- Migration 005: Audit logs + subscription/trial fields
-- Ported from Rew (realestate-saas) lib/audit.ts
-- ============================================================

-- ─── Audit logs ──────────────────────────────────────────────
-- Append-only, immutable record of every write mutation.
-- Never exposed via anonymous roles — backend service role only.
CREATE TABLE IF NOT EXISTS `audit_logs` (
    `id`          BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `tenant_id`   VARCHAR(36)      NOT NULL,
    `action`      ENUM('create','update','delete','publish') NOT NULL,
    `resource`    ENUM('listing','inquiry','announcement','profile','gallery','team','payment') NOT NULL,
    `resource_id` VARCHAR(36)      NOT NULL,
    `user_id`     VARCHAR(255)     NOT NULL,
    `before`      JSON             NULL     COMMENT 'State snapshot before mutation',
    `after`       JSON             NULL     COMMENT 'State snapshot after mutation',
    `ip_address`  VARCHAR(45)      NULL     COMMENT 'IPv4 or IPv6',
    `created_at`  TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX `idx_tenant_resource`  (`tenant_id`, `resource`),
    INDEX `idx_resource_id`      (`resource_id`),
    INDEX `idx_user_id`          (`user_id`),
    INDEX `idx_created_at`       (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── Subscription / trial state on tenants ───────────────────
-- Mirrors the fields consumed by Rew's getTenantTrialState().
ALTER TABLE `tenants`
    ADD COLUMN IF NOT EXISTS `trial_started_at`  TIMESTAMP NULL
        COMMENT 'When the trial period began'
        AFTER `plan`,
    ADD COLUMN IF NOT EXISTS `trial_expires_at`  TIMESTAMP NULL
        COMMENT 'When the trial period ends (NULL = no trial configured)'
        AFTER `trial_started_at`,
    ADD COLUMN IF NOT EXISTS `billing_status`    ENUM('paid','pending','failed','unpaid') NOT NULL DEFAULT 'unpaid'
        COMMENT 'Current billing state; paid = active subscription'
        AFTER `trial_expires_at`;

ALTER TABLE `tenants`
    ADD INDEX IF NOT EXISTS `idx_billing_status` (`billing_status`),
    ADD INDEX IF NOT EXISTS `idx_trial_expires`  (`trial_expires_at`);
