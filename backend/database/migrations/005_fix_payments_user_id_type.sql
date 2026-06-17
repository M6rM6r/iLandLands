-- Migration 005: Fix payments.user_id type mismatch
-- Date: 2024-06-17
-- Description: payments.user_id was INT UNSIGNED but users.id is VARCHAR(36).
--              This broke the foreign key constraint. Change to VARCHAR(36).

ALTER TABLE `payments`
    DROP FOREIGN KEY IF EXISTS `fk_payments_user`;

ALTER TABLE `payments`
    MODIFY COLUMN `user_id` VARCHAR(36) NULL;

ALTER TABLE `payments`
    ADD CONSTRAINT `fk_payments_user`
        FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
