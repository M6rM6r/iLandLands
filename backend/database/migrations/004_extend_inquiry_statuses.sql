-- Migration 004: Extend contact_inquiries status enum for Kanban pipeline
-- Date: 2024-06-17
-- Description: Adds pipeline statuses (contacted, scheduled, visited, negotiating, won, lost)
--              to support the admin dashboard Kanban board.

-- MySQL does not allow direct ALTER TYPE on ENUM columns.
-- We must recreate the column with the new enum values.

ALTER TABLE `contact_inquiries`
    MODIFY COLUMN `status`
    ENUM('new','contacted','scheduled','visited','negotiating','won','lost','read','replied','closed')
    NOT NULL DEFAULT 'new';
