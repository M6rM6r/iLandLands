-- Migration 003: Add payments table (Telr integration)
-- Safe to re-run: uses CREATE TABLE IF NOT EXISTS
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `payments` (
    `id`             INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `cart_id`        VARCHAR(64)      NOT NULL UNIQUE,
    `tenant_id`      CHAR(36)         NOT NULL,
    `user_id`        INT UNSIGNED     NULL,
    `listing_id`     VARCHAR(36)      NULL,
    `telr_order_id`  VARCHAR(64)      NULL,
    `amount`         DECIMAL(15, 2)   NOT NULL,
    `currency`       CHAR(3)          NOT NULL DEFAULT 'AED',
    `status`         ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
    `created_at`     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME         NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_payments_tenant`       (`tenant_id`),
    INDEX `idx_payments_status`       (`status`),
    INDEX `idx_payments_telr_order`   (`telr_order_id`),
    CONSTRAINT `fk_payments_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_payments_user`
        FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_payments_listing`
        FOREIGN KEY (`listing_id`) REFERENCES `land_listings` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
