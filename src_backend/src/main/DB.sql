-- ===========================
-- RESET DATABASE (safe re-run)
-- ===========================
-- DROP TABLE IF EXISTS transactions CASCADE;
-- DROP TABLE IF EXISTS orders CASCADE;
-- DROP TABLE IF EXISTS flashcards CASCADE;
-- DROP TABLE IF EXISTS categories CASCADE;
-- DROP TABLE IF EXISTS classes CASCADE;
-- DROP TABLE IF EXISTS studyPacks CASCADE;
-- DROP TABLE IF EXISTS otpVerification CASCADE;
-- DROP TABLE IF EXISTS policies CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- ===========================
-- USERS
-- ===========================
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  fullName VARCHAR(255) NOT NULL,
  passwordHash VARCHAR(255) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'UNVERIFIED',
  dob DATE,
  role VARCHAR(50) NOT NULL DEFAULT 'NORMAL_USER',
  isBlocked BOOLEAN NOT NULL DEFAULT FALSE,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE otpVerification (
  id SERIAL PRIMARY KEY,
  userId INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  otpCode VARCHAR(6) NOT NULL,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiresAt TIMESTAMPTZ NOT NULL,
  isVerified BOOLEAN NOT NULL DEFAULT FALSE,
  verificationType VARCHAR(50) NOT NULL DEFAULT 'REGISTRATION'
);

-- Tạo chỉ mục chỉ khi chưa tồn tại
CREATE INDEX IF NOT EXISTS idx_otp_user_id ON otpVerification(userId);
CREATE INDEX IF NOT EXISTS idx_otp_code ON otpVerification(otpCode);

-- ===========================
-- POLICIES
-- ===========================
CREATE TABLE policies (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===========================
-- Table: studyPacks
-- ===========================
CREATE TABLE IF NOT EXISTS studyPacks (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,   -- Tên hiển thị
  description TEXT,             -- Mô tả chi tiết
  price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  durationDays INTEGER NOT NULL DEFAULT 30 CHECK (durationDays > 0), -- thời hạn

  -- pack này dành cho loại role nào
  targetRole VARCHAR(20) NOT NULL,
  CONSTRAINT chk_studyPacks_targetRole
    CHECK (targetRole IN ('NORMAL_USER', 'TEACHER', 'ADMIN', 'PREMIUM_USER')),

  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deletedAt TIMESTAMPTZ
);

-- ===========================
-- PACK PURCHASES
-- ===========================
CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  userId INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  packId INTEGER NOT NULL REFERENCES studyPacks(id) ON DELETE RESTRICT,
  priceAtPurchase NUMERIC(12,2) NOT NULL CHECK (priceAtPurchase >= 0),
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING'
                   CHECK (status IN ('PENDING','PAID','CANCELED','REFUNDED','FAILED')),
  startedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiresAt TIMESTAMPTZ,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tạo chỉ mục chỉ khi chưa tồn tại
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(userId);
CREATE INDEX IF NOT EXISTS idx_orders_pack ON orders(packId);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_dates ON orders(startedAt, expiresAt);

-- ===========================
-- TRANSACTIONS
-- ===========================
CREATE TABLE IF NOT EXISTS transactions (
  id SERIAL PRIMARY KEY,
  orderId INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  provider VARCHAR(50),
  method VARCHAR(50),
  providerTxnId VARCHAR(120),
  status VARCHAR(30) NOT NULL DEFAULT 'INIT'
                   CHECK (status IN ('INIT','SUCCEEDED','FAILED','REFUNDED')),
  rawPayload JSONB DEFAULT '{}'::jsonb,
  message TEXT,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tạo chỉ mục chỉ khi chưa tồn tại
CREATE INDEX IF NOT EXISTS idx_transactions_purchase ON transactions(orderId);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);

-- tránh trùng mã giao dịch từ cổng
CREATE UNIQUE INDEX IF NOT EXISTS uq_transactions_provider_txnid
  ON transactions (COALESCE(provider, '~'), COALESCE(providerTxnId, '~'))
  WHERE providerTxnId IS NOT NULL;

-- ===========================
-- CLASSES (LỚP HỌC)
-- ===========================
CREATE TABLE IF NOT EXISTS classes (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,              -- Tên lớp
  description TEXT,
  ownerId INTEGER REFERENCES users(id) ON DELETE SET NULL,  -- giáo viên / người tạo lớp
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===========================
-- CATEGORIES
-- ===========================
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,

  isSystem BOOLEAN NOT NULL DEFAULT FALSE,
  ownerUserId INTEGER REFERENCES users(id) ON DELETE CASCADE,

  classId INTEGER REFERENCES classes(id) ON DELETE SET NULL,

  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE categories
ADD CONSTRAINT chk_categories_owner
CHECK (
  (isSystem = TRUE  AND ownerUserId IS NULL) OR
  (isSystem = FALSE AND ownerUserId IS NOT NULL)
);

-- ===========================
-- FLASHCARDS
-- ===========================
CREATE TABLE flashcards (
  id SERIAL PRIMARY KEY,          
  term VARCHAR(255) NOT NULL,    
  partOfSpeech VARCHAR(50),    
  phonetic VARCHAR(100),         
  imageUrl TEXT,                
  meaning TEXT NOT NULL,         
  categoryId INT,
  ttsUrl TEXT,
  FOREIGN KEY (categoryId)
    REFERENCES categories(id) ON DELETE SET NULL
);

-- ===========================
-- SEED DATA
-- ===========================

-- USERS
INSERT INTO users (email, fullName, passwordHash, status, dob, role, isBlocked) VALUES
('teacher@example.com', 'Teacher User', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2000-12-12', 'TEACHER', FALSE),
('ly@gmail.com', 'Ly User', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2003-06-12', 'NORMAL_USER', FALSE),
('admin@example.com', 'Admin User', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2000-12-12', 'ADMIN', FALSE),
('blocked@example.com', 'Blocked User', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1999-03-15', 'NORMAL_USER', TRUE),
('premium@example.com', 'Premium User', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2001-08-20', 'PREMIUM_USER', FALSE);

-- POLICIES
INSERT INTO policies (title, body, status) VALUES
('Điều khoản sử dụng',
 'Quy định về việc tạo tài khoản, bảo mật mật khẩu, giới hạn trách nhiệm và quyền chấm dứt dịch vụ. Người dùng phải tuân thủ pháp luật hiện hành và không lạm dụng hệ thống.',
 'ACTIVE'),

('Chính sách quyền riêng tư',
 'Mô tả loại dữ liệu thu thập (email, log truy cập), mục đích sử dụng, thời gian lưu trữ và quyền yêu cầu xoá/sửa dữ liệu cá nhân theo quy định.',
 'ACTIVE'),

('Chính sách cookie',
 'Hệ thống dùng cookie cho phiên đăng nhập và phân tích lưu lượng. Bạn có thể tắt cookie không thiết yếu trong phần cài đặt.',
 'ACTIVE'),

('Nguyên tắc cộng đồng',
 'Cấm nội dung thù hằn, quấy rối, spam và hành vi gây hại. Vi phạm có thể bị khoá tài khoản tạm thời hoặc vĩnh viễn.',
 'ACTIVE'),

('Chính sách bảo mật hệ thống',
 'Mô tả biện pháp mã hoá, sao lưu, quy trình xử lý sự cố và báo cáo lỗ hổng (responsible disclosure).',
 'ACTIVE'),

('Điều khoản thanh toán & hoàn tiền',
 'Thanh toán qua các cổng hỗ trợ. Hoàn tiền trong 7 ngày cho các lỗi hệ thống nghiêm trọng; không áp dụng cho lạm dụng.',
 'ACTIVE'),

('Chính sách lưu trữ & xoá dữ liệu',
 'Xoá mềm sau 30 ngày, xoá cứng sau 90 ngày hoặc theo yêu cầu hợp lệ của người dùng/đơn vị quản lý.',
 'DRAFT'),

('Chính sách phiên bản beta',
 'Tính năng beta có thể thay đổi không báo trước; có thể ghi log nâng cao để cải thiện chất lượng.',
 'INACTIVE');

-- STUDY PACKS
INSERT INTO studyPacks (name, description, price, durationDays, targetRole) VALUES
('Basic 30 ngày', 'Gói cơ bản: học, ôn tập tiêu chuẩn, không quảng cáo.', 159000, 30, 'NORMAL_USER'),
('Pro tháng', 'Mở khoá tính năng nâng cao, ưu tiên tài nguyên.', 239000, 30, 'NORMAL_USER'),
('Pro năm', 'Trọn năm Pro, tiết kiệm so với trả tháng.', 1990000, 365, 'NORMAL_USER'),
('Teacher Premium tháng', 'Gói Premium dành cho giáo viên: tạo lớp, quản lý học viên.', 399000, 30, 'TEACHER'),
('Teacher Premium năm', 'Gói Premium dành cho giáo viên tiết kiệm hơn với 1 năm: tạo lớp, quản lý học viên.', 2399000, 365, 'TEACHER');

-- 1 ORDER mẫu: user #1 mua pack #2 (Pro tháng) 30 ngày
INSERT INTO orders
(userId, packId, priceAtPurchase, status, startedAt, expiresAt, createdAt, updatedAt)
VALUES
(1, 2, 239000, 'PAID', NOW(), NOW() + INTERVAL '30 days', NOW(), NOW());

-- 1 TRANSACTION mẫu cho order #1
INSERT INTO transactions
(orderId, amount, provider, method, providerTxnId, status, message, createdAt, updatedAt)
VALUES
(1, 239000, 'MoMo', 'WALLET', 'MOMO-SEED-0001', 'SUCCEEDED', 'Thanh toán thành công', NOW(), NOW());

-- Lệnh kiểm tra cuối cùng
SELECT * FROM classes;
SELECT * FROM categories;
SELECT * FROM flashcards;
SELECT * FROM users;
SELECT * FROM studyPacks;
