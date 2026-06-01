-- Migration: 002_multi_tenant.sql
-- Adds multi-tenant support to an existing v1 database.
-- Safe to re-run (uses IF NOT EXISTS / IF EXISTS guards).
-- Run as: mysql -u root -p gulflands < 002_multi_tenant.sql

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET foreign_key_checks = 0;

-- ─────────────────────────────────────────────
-- 1. Create tenants table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `tenants` (
    `id`         VARCHAR(36)  NOT NULL PRIMARY KEY DEFAULT (UUID()),
    `name`       VARCHAR(255) NOT NULL,
    `slug`       VARCHAR(100) NOT NULL,
    `plan`       ENUM('free','pro','enterprise') NOT NULL DEFAULT 'free',
    `status`     ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
    `settings`   JSON         NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY `uq_slug` (`slug`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- 2. Insert default tenant (idempotent)
-- ─────────────────────────────────────────────
SET @default_tenant_id = 'a0000000-0000-0000-0000-000000000001';

INSERT INTO `tenants` (`id`, `name`, `slug`, `plan`, `status`)
SELECT @default_tenant_id, 'Gulf Lands Market', 'gulf-lands-market', 'enterprise', 'active'
WHERE NOT EXISTS (SELECT 1 FROM `tenants` WHERE `id` = @default_tenant_id);

-- ─────────────────────────────────────────────
-- 3. land_listings — add tenant_id
-- ─────────────────────────────────────────────
ALTER TABLE `land_listings`
    ADD COLUMN IF NOT EXISTS `tenant_id` VARCHAR(36) NOT NULL
        DEFAULT 'a0000000-0000-0000-0000-000000000001'
        AFTER `id`;

ALTER TABLE `land_listings`
    ADD INDEX IF NOT EXISTS `idx_tenant_country`  (`tenant_id`, `country`),
    ADD INDEX IF NOT EXISTS `idx_tenant_status`   (`tenant_id`, `status`),
    ADD INDEX IF NOT EXISTS `idx_tenant_featured` (`tenant_id`, `is_featured`);

-- Drop the old single-column indexes that are now redundant
ALTER TABLE `land_listings`
    DROP INDEX IF EXISTS `idx_country`,
    DROP INDEX IF EXISTS `idx_status`,
    DROP INDEX IF EXISTS `idx_featured`;

ALTER TABLE `land_listings`
    ADD CONSTRAINT IF NOT EXISTS `fk_listings_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE;

-- ─────────────────────────────────────────────
-- 4. users — add tenant_id + role
-- ─────────────────────────────────────────────
ALTER TABLE `users`
    ADD COLUMN IF NOT EXISTS `tenant_id` VARCHAR(36) NOT NULL
        DEFAULT 'a0000000-0000-0000-0000-000000000001'
        AFTER `id`,
    ADD COLUMN IF NOT EXISTS `role`
        ENUM('admin','manager','agent','viewer') NOT NULL DEFAULT 'viewer'
        AFTER `email_verified`;

-- Replace old global unique email with tenant-scoped unique
ALTER TABLE `users`
    DROP INDEX IF EXISTS `email`;

ALTER TABLE `users`
    ADD UNIQUE KEY IF NOT EXISTS `uq_tenant_email` (`tenant_id`, `email`),
    ADD INDEX IF NOT EXISTS `idx_tenant_status` (`tenant_id`, `status`),
    ADD INDEX IF NOT EXISTS `idx_tenant_role`   (`tenant_id`, `role`);

ALTER TABLE `users`
    ADD CONSTRAINT IF NOT EXISTS `fk_users_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE;

-- ─────────────────────────────────────────────
-- 5. user_favorites — add tenant_id
-- ─────────────────────────────────────────────
ALTER TABLE `user_favorites`
    ADD COLUMN IF NOT EXISTS `tenant_id` VARCHAR(36) NOT NULL
        DEFAULT 'a0000000-0000-0000-0000-000000000001'
        AFTER `id`;

ALTER TABLE `user_favorites`
    DROP INDEX IF EXISTS `unique_user_land`;

ALTER TABLE `user_favorites`
    ADD UNIQUE KEY IF NOT EXISTS `uq_tenant_user_land` (`tenant_id`, `user_id`, `land_id`),
    ADD INDEX IF NOT EXISTS `idx_tenant_user` (`tenant_id`, `user_id`);

ALTER TABLE `user_favorites`
    ADD CONSTRAINT IF NOT EXISTS `fk_favorites_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE;

-- ─────────────────────────────────────────────
-- 6. analytics_events — add tenant_id
-- ─────────────────────────────────────────────
ALTER TABLE `analytics_events`
    ADD COLUMN IF NOT EXISTS `tenant_id` VARCHAR(36) NOT NULL
        DEFAULT 'a0000000-0000-0000-0000-000000000001'
        AFTER `id`;

ALTER TABLE `analytics_events`
    DROP INDEX IF EXISTS `idx_event_name`,
    DROP INDEX IF EXISTS `idx_ip_address`;

ALTER TABLE `analytics_events`
    ADD INDEX IF NOT EXISTS `idx_tenant_event` (`tenant_id`, `event_name`),
    ADD INDEX IF NOT EXISTS `idx_tenant_user`  (`tenant_id`, `user_id`);

ALTER TABLE `analytics_events`
    ADD CONSTRAINT IF NOT EXISTS `fk_events_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE;

-- ─────────────────────────────────────────────
-- 7. search_queries — add tenant_id
-- ─────────────────────────────────────────────
ALTER TABLE `search_queries`
    ADD COLUMN IF NOT EXISTS `tenant_id` VARCHAR(36) NOT NULL
        DEFAULT 'a0000000-0000-0000-0000-000000000001'
        AFTER `id`;

ALTER TABLE `search_queries`
    ADD INDEX IF NOT EXISTS `idx_tenant_query`   (`tenant_id`, `query`),
    ADD INDEX IF NOT EXISTS `idx_tenant_country` (`tenant_id`, `country`);

ALTER TABLE `search_queries`
    DROP INDEX IF EXISTS `idx_query`,
    DROP INDEX IF EXISTS `idx_country`;

ALTER TABLE `search_queries`
    ADD CONSTRAINT IF NOT EXISTS `fk_searches_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE;

-- ─────────────────────────────────────────────
-- 8. contact_inquiries — add tenant_id
-- ─────────────────────────────────────────────
ALTER TABLE `contact_inquiries`
    ADD COLUMN IF NOT EXISTS `tenant_id` VARCHAR(36) NOT NULL
        DEFAULT 'a0000000-0000-0000-0000-000000000001'
        AFTER `id`;

ALTER TABLE `contact_inquiries`
    ADD INDEX IF NOT EXISTS `idx_tenant_status` (`tenant_id`, `status`),
    ADD INDEX IF NOT EXISTS `idx_tenant_user`   (`tenant_id`, `user_id`);

ALTER TABLE `contact_inquiries`
    DROP INDEX IF EXISTS `idx_status`;

ALTER TABLE `contact_inquiries`
    ADD CONSTRAINT IF NOT EXISTS `fk_inquiries_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE;

-- ─────────────────────────────────────────────
-- 9. system_settings — add nullable tenant_id
-- ─────────────────────────────────────────────
ALTER TABLE `system_settings`
    ADD COLUMN IF NOT EXISTS `tenant_id` VARCHAR(36) NULL
        AFTER `id`;

ALTER TABLE `system_settings`
    DROP INDEX IF EXISTS `setting_key`;

ALTER TABLE `system_settings`
    ADD UNIQUE KEY IF NOT EXISTS `uq_tenant_key` (`tenant_id`, `setting_key`),
    ADD INDEX IF NOT EXISTS `idx_tenant_id` (`tenant_id`);

ALTER TABLE `system_settings`
    ADD CONSTRAINT IF NOT EXISTS `fk_settings_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE;

-- ─────────────────────────────────────────────
-- 10. Refresh views (tenant-aware)
-- ─────────────────────────────────────────────
CREATE OR REPLACE VIEW `popular_listings` AS
SELECT
    ll.*,
    COUNT(uf.id) AS favorite_count
FROM `land_listings` ll
LEFT JOIN `user_favorites` uf ON ll.id = uf.land_id
WHERE ll.status = 'active'
GROUP BY ll.id
ORDER BY favorite_count DESC, ll.created_at DESC;

CREATE OR REPLACE VIEW `analytics_summary` AS
SELECT
    tenant_id,
    DATE(created_at)  AS date,
    event_name,
    COUNT(*)          AS cnt
FROM `analytics_events`
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY tenant_id, DATE(created_at), event_name
ORDER BY date DESC, cnt DESC;

SET foreign_key_checks = 1;
