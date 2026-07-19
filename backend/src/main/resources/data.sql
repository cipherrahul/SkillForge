INSERT INTO users (id, email, password_hash, full_name, role, enabled, created_at, updated_at, is_deleted) VALUES
('11111111-1111-1111-1111-111111111111', 'admin@skillforge.dev', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxbelVg8pFNoWgC1.', 'Admin User', 'ADMIN', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, false),
('22222222-2222-2222-2222-222222222222', 'test@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.', 'Test Student', 'STUDENT', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, false);
