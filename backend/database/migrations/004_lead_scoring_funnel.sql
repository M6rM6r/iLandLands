-- ============================================================
-- Migration 004: Lead scoring + funnel event tracking
-- Ported from Rew (realestate-saas) lead-scoring engine.
-- ============================================================

-- ─── Add lead score columns to contact_inquiries ────────────
ALTER TABLE `contact_inquiries`
    ADD COLUMN `lead_score` TINYINT(3) UNSIGNED NOT NULL DEFAULT 0
        COMMENT '0-100 deterministic lead score (LeadScoringService)'
        AFTER `status`,
    ADD COLUMN `lead_band`  ENUM('hot','warm','cold','low') NOT NULL DEFAULT 'low'
        COMMENT 'Score band: hot≥80, warm≥55, cold≥30, low<30'
        AFTER `lead_score`;

ALTER TABLE `contact_inquiries`
    ADD INDEX `idx_tenant_band` (`tenant_id`, `lead_band`),
    ADD INDEX `idx_lead_score`  (`lead_score`);

-- ─── Funnel events table ─────────────────────────────────────
-- Best-effort, append-only analytics store.
-- Modelled after Rew's Firestore funnel_events collection,
-- adapted for MySQL with a JSON metadata column.
--
-- Known event names:
--   inquiry_created     — new contact inquiry submitted
--   payment_succeeded   — Telr callback: status = completed
--   payment_failed      — Telr callback: status = failed
--   user_registered     — new tenant user created
CREATE TABLE IF NOT EXISTS `funnel_events` (
    `id`         BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `tenant_id`  VARCHAR(36)      NULL     COMMENT 'NULL = platform-level event',
    `event_name` VARCHAR(80)      NOT NULL,
    `metadata`   JSON             NOT NULL,
    `created_at` TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX `idx_tenant_event`  (`tenant_id`, `event_name`),
    INDEX `idx_event_created` (`event_name`, `created_at`),
    INDEX `idx_created_at`    (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
