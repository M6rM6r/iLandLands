-- Gulf Lands Database Schema v2
-- Multi-tenant SaaS edition

-- Enable UTF-8 support
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- Tenants Table (root of multi-tenancy)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `tenants` (
    `id`          VARCHAR(36)  NOT NULL PRIMARY KEY DEFAULT (UUID()),
    `name`        VARCHAR(255) NOT NULL,
    `slug`        VARCHAR(100) NOT NULL COMMENT 'URL-safe identifier, e.g. acme-realty',
    `plan`        ENUM('free','pro','enterprise') NOT NULL DEFAULT 'free',
    `status`      ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
    `settings`    JSON         NULL COMMENT 'Per-tenant feature flags and config',
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY `uq_slug` (`slug`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- Land Listings Table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `land_listings` (
    `id`          VARCHAR(36)  NOT NULL PRIMARY KEY DEFAULT (UUID()),
    `tenant_id`   VARCHAR(36)  NOT NULL,
    `title`       VARCHAR(255) NOT NULL,
    `description` TEXT         NOT NULL,
    `price`       DECIMAL(15,2) NOT NULL,
    `area`        DECIMAL(10,2) NOT NULL COMMENT 'Area in square meters',
    `country`     ENUM('saudiArabia','uae','qatar','bahrain','oman','kuwait') NOT NULL,
    `location`    VARCHAR(255) NOT NULL,
    `image_urls`  JSON         NOT NULL,
    `is_featured` BOOLEAN      NOT NULL DEFAULT FALSE,
    `status`      ENUM('active','inactive','sold','pending') NOT NULL DEFAULT 'active',
    `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX `idx_tenant_country`  (`tenant_id`, `country`),
    INDEX `idx_tenant_status`   (`tenant_id`, `status`),
    INDEX `idx_tenant_featured` (`tenant_id`, `is_featured`),
    INDEX `idx_price`           (`price`),
    INDEX `idx_area`            (`area`),
    INDEX `idx_created_at`      (`created_at`),
    INDEX `idx_location`        (`location`(100)),

    FULLTEXT INDEX `ft_search` (`title`, `description`, `location`),

    CONSTRAINT `fk_listings_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- Users Table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `users` (
    `id`             VARCHAR(36)  NOT NULL PRIMARY KEY DEFAULT (UUID()),
    `tenant_id`      VARCHAR(36)  NOT NULL,
    `email`          VARCHAR(255) NOT NULL,
    `password_hash`  VARCHAR(255) NULL,
    `first_name`     VARCHAR(100) NULL,
    `last_name`      VARCHAR(100) NULL,
    `phone`          VARCHAR(20)  NULL,
    `role`           ENUM('admin','manager','agent','viewer') NOT NULL DEFAULT 'viewer',
    `country`        ENUM('saudiArabia','uae','qatar','bahrain','oman','kuwait') NULL,
    `status`         ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
    `email_verified` BOOLEAN      NOT NULL DEFAULT FALSE,
    `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY `uq_tenant_email` (`tenant_id`, `email`),
    INDEX `idx_tenant_status`  (`tenant_id`, `status`),
    INDEX `idx_tenant_role`    (`tenant_id`, `role`),

    CONSTRAINT `fk_users_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- User Favorites Table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `user_favorites` (
    `id`         INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `tenant_id`  VARCHAR(36)  NOT NULL,
    `user_id`    VARCHAR(255) NOT NULL,
    `land_id`    VARCHAR(36)  NOT NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY `uq_tenant_user_land` (`tenant_id`, `user_id`, `land_id`),
    INDEX `idx_tenant_user`  (`tenant_id`, `user_id`),
    INDEX `idx_land_id`      (`land_id`),

    CONSTRAINT `fk_favorites_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_favorites_land`
        FOREIGN KEY (`land_id`) REFERENCES `land_listings`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- Analytics Events Table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `analytics_events` (
    `id`         BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `tenant_id`  VARCHAR(36)  NOT NULL,
    `event_name` VARCHAR(100) NOT NULL,
    `user_id`    VARCHAR(255) NULL,
    `session_id` VARCHAR(255) NULL,
    `properties` JSON         NULL,
    `user_agent` TEXT         NULL,
    `ip_address` VARCHAR(45)  NULL,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX `idx_tenant_event`   (`tenant_id`, `event_name`),
    INDEX `idx_tenant_user`    (`tenant_id`, `user_id`),
    INDEX `idx_session_id`     (`session_id`),
    INDEX `idx_created_at`     (`created_at`),

    CONSTRAINT `fk_events_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- Search Queries Table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `search_queries` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `tenant_id`     VARCHAR(36)  NOT NULL,
    `query`         VARCHAR(255) NOT NULL,
    `country`       ENUM('saudiArabia','uae','qatar','bahrain','oman','kuwait') NULL,
    `results_count` INT          NOT NULL DEFAULT 0,
    `user_id`       VARCHAR(255) NULL,
    `session_id`    VARCHAR(255) NULL,
    `ip_address`    VARCHAR(45)  NULL,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX `idx_tenant_query`   (`tenant_id`, `query`),
    INDEX `idx_tenant_country` (`tenant_id`, `country`),
    INDEX `idx_created_at`     (`created_at`),

    CONSTRAINT `fk_searches_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- Contact Inquiries Table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `contact_inquiries` (
    `id`         VARCHAR(36)  NOT NULL PRIMARY KEY DEFAULT (UUID()),
    `tenant_id`  VARCHAR(36)  NOT NULL,
    `land_id`    VARCHAR(36)  NULL,
    `user_id`    VARCHAR(255) NULL,
    `name`       VARCHAR(255) NOT NULL,
    `email`      VARCHAR(255) NOT NULL,
    `phone`      VARCHAR(20)  NULL,
    `message`    TEXT         NOT NULL,
    `status`     ENUM('new','read','replied','closed') NOT NULL DEFAULT 'new',
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX `idx_tenant_status`  (`tenant_id`, `status`),
    INDEX `idx_tenant_user`    (`tenant_id`, `user_id`),
    INDEX `idx_land_id`        (`land_id`),
    INDEX `idx_created_at`     (`created_at`),

    CONSTRAINT `fk_inquiries_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_inquiries_land`
        FOREIGN KEY (`land_id`) REFERENCES `land_listings`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- System Settings Table (global or per-tenant)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `system_settings` (
    `id`            INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `tenant_id`     VARCHAR(36)  NULL COMMENT 'NULL = global platform setting',
    `setting_key`   VARCHAR(100) NOT NULL,
    `setting_value` TEXT         NULL,
    `description`   TEXT         NULL,
    `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY `uq_tenant_key` (`tenant_id`, `setting_key`),
    INDEX `idx_tenant_id` (`tenant_id`),

    CONSTRAINT `fk_settings_tenant`
        FOREIGN KEY (`tenant_id`) REFERENCES `tenants`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- Seed Data
-- ─────────────────────────────────────────────

-- Default tenant (used for seed listings and initial setup)
SET @default_tenant_id = 'a0000000-0000-0000-0000-000000000001';

INSERT INTO `tenants` (`id`, `name`, `slug`, `plan`, `status`) VALUES
(@default_tenant_id, 'Gulf Lands Market', 'gulf-lands-market', 'enterprise', 'active')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Sample listings (all under the default tenant)
INSERT INTO `land_listings` (`id`, `tenant_id`, `title`, `description`, `price`, `area`, `country`, `location`, `image_urls`, `is_featured`) VALUES
('1', @default_tenant_id, 'Prime Coastal Land in Jeddah', 'A stunning piece of land with direct access to the Red Sea. Perfect for a luxury villa or a private resort.', 5000000.00, 10000.00, 'saudiArabia', 'Jeddah, Obhur', '["https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800"]', TRUE),
('2', @default_tenant_id, 'Exclusive Plot in Dubai Hills Estate', 'Located in one of the most prestigious communities in Dubai, offering stunning views of the golf course.', 12000000.00, 15000.00, 'uae', 'Dubai, Dubai Hills Estate', '["https://images.unsplash.com/photo-1512459979262-d0dc91538e8e?w=800"]', TRUE),
('3', @default_tenant_id, 'Sea View Land in The Pearl, Qatar', 'An exceptional opportunity to build your dream home in one of the most sought-after locations in Doha.', 9500000.00, 8000.00, 'qatar', 'Doha, The Pearl-Qatar', '["https://images.unsplash.com/photo-1548197673-52cce8bf8b22?w=800"]', TRUE),
('4', @default_tenant_id, 'Large Agricultural Land in Al-Ahsa', 'A vast expanse of fertile land, perfect for agricultural projects. Comes with water access.', 2500000.00, 50000.00, 'saudiArabia', 'Al-Ahsa', '["https://images.unsplash.com/photo-1590585151119-1b5490c3b16d?w=800"]', FALSE),
('5', @default_tenant_id, 'Luxury Residential Plot in Riyadh', 'Prime residential location in Riyadh with excellent infrastructure and amenities nearby.', 7500000.00, 12000.00, 'saudiArabia', 'Riyadh, Al-Malqa District', '["https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800"]', FALSE),
('6', @default_tenant_id, 'Commercial Land in Abu Dhabi', 'Strategic commercial location with high visibility and accessibility.', 15000000.00, 20000.00, 'uae', 'Abu Dhabi, City Center', '["https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800"]', FALSE),
('7', @default_tenant_id, 'Beachfront Land in Kuwait', 'Beautiful beachfront property with stunning views of the Persian Gulf.', 8500000.00, 9000.00, 'kuwait', 'Kuwait City, Salmiya', '["https://images.unsplash.com/photo-1505142468610-359e7d3bebe6?w=800"]', FALSE),
('8', @default_tenant_id, 'Mountain View Land in Oman', 'Scenic mountain location perfect for eco-tourism or retreat development.', 3200000.00, 18000.00, 'oman', 'Muscat, Jabal Akhdar', '["https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800"]', FALSE),
('9', @default_tenant_id, 'Island Paradise in Bahrain', 'Exclusive island property offering privacy and luxury.', 11000000.00, 11000.00, 'bahrain', 'Manama, Amwaj Islands', '["https://images.unsplash.com/photo-1540202404-1c6ea2cd2c19?w=800"]', FALSE),
('10', @default_tenant_id, 'Desert Oasis Land', 'Unique desert property with natural spring and potential for resort development.', 4200000.00, 25000.00, 'saudiArabia', 'Riyadh Province', '["https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=800"]', FALSE);

-- Seed admin user (dev only — change password before any real deployment)
INSERT INTO `users` (`id`, `tenant_id`, `email`, `password_hash`, `country`, `role`, `status`, `created_at`) VALUES
('u0000000-0000-0000-0000-000000000001', @default_tenant_id, 'admin@gulflands.dev', '$2y$12$ZoQTFRxXOcMGwlslfMST9.lYgNkvsoEJAsc23caiF0yCBwM1FP5fS', 'uae', 'admin', 'active', NOW())
ON DUPLICATE KEY UPDATE `email` = VALUES(`email`);

-- Global system settings (tenant_id = NULL)
INSERT INTO `system_settings` (`tenant_id`, `setting_key`, `setting_value`, `description`) VALUES
(NULL, 'site_name', 'Gulf Lands Market', 'The name of the website'),
(NULL, 'site_description', 'Premium land listings across the Gulf region', 'Site description for SEO'),
(NULL, 'contact_email', 'info@gulflands.com', 'Contact email address'),
(NULL, 'max_upload_size', '10485760', 'Maximum file upload size in bytes'),
(NULL, 'featured_listings_count', '6', 'Number of featured listings to display'),
(NULL, 'analytics_retention_days', '90', 'Number of days to retain analytics data'),
(NULL, 'enable_search_tracking', 'true', 'Enable search query tracking'),
(NULL, 'default_country', 'saudiArabia', 'Default country for new listings');

-- ─────────────────────────────────────────────
-- Utility Views
-- ─────────────────────────────────────────────

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

-- ─────────────────────────────────────────────
-- Utility Views
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

-- Performance optimization: Partition analytics_events table by month
ALTER TABLE `analytics_events` 
PARTITION BY RANGE (TO_DAYS(created_at)) (
    PARTITION p_current VALUES LESS THAN (TO_DAYS(DATE_ADD(CURRENT_DATE, INTERVAL 1 MONTH))),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Add triggers for automatic analytics updates
DELIMITER //
CREATE TRIGGER `track_listing_view` 
AFTER INSERT ON `analytics_events`
FOR EACH ROW
BEGIN
    IF NEW.event_name = 'listing_viewed' THEN
        UPDATE `land_listings` 
        SET `updated_at` = CURRENT_TIMESTAMP 
        WHERE `id` = JSON_UNQUOTE(JSON_EXTRACT(NEW.properties, '$.listing_id'));
    END IF;
END//
DELIMITER ;

-- Add stored procedures for common operations
DELIMITER //
CREATE PROCEDURE `get_listings_with_stats`(IN p_country VARCHAR(50), IN p_limit INT)
BEGIN
    SELECT 
        ll.*,
        COUNT(uf.id) as favorite_count,
        (SELECT COUNT(*) FROM `analytics_events` ae 
         WHERE ae.event_name = 'listing_viewed' 
         AND JSON_EXTRACT(ae.properties, '$.listing_id') = ll.id) as view_count
    FROM `land_listings` ll
    LEFT JOIN `user_favorites` uf ON ll.id = uf.land_id
    WHERE ll.status = 'active' 
    AND (p_country IS NULL OR ll.country = p_country)
    GROUP BY ll.id
    ORDER BY ll.is_featured DESC, view_count DESC
    LIMIT p_limit;
END//
DELIMITER ;

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON gulflands.* TO 'gulflands_user'@'localhost';
-- FLUSH PRIVILEGES;
