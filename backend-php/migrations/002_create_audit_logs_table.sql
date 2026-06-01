-- Migration: Create audit_logs table
CREATE TABLE audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    action ENUM('create', 'update', 'delete', 'publish') NOT NULL,
    listing_id VARCHAR(255) NOT NULL,
    actor VARCHAR(100) NOT NULL,
    changed_fields JSON,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);