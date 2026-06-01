-- Seeder: Insert admin user
-- IMPORTANT: Change this password immediately after first login.
-- Generate a new bcrypt hash: php -r "echo password_hash('YOUR_PASSWORD', PASSWORD_BCRYPT, ['cost' => 12]);"
INSERT INTO admins (username, password_hash, role) VALUES
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE username = username;