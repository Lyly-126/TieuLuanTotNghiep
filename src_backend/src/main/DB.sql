-- ===========================
-- RESET DATABASE (safe re-run)
-- ===========================
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS flashcards CASCADE;
DROP TABLE IF EXISTS userSavedCategories CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS "classMembers" CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS studyPacks CASCADE;
DROP TABLE IF EXISTS otpVerification CASCADE;
DROP TABLE IF EXISTS policies CASCADE;
DROP TABLE IF EXISTS users CASCADE;
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

CREATE INDEX idx_otp_user_id ON otpVerification(userId);
CREATE INDEX idx_otp_code ON otpVerification(otpCode);

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
-- STUDY PACKS
-- ===========================
CREATE TABLE studyPacks (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  durationDays INTEGER NOT NULL DEFAULT 30 CHECK (durationDays > 0),
  targetRole VARCHAR(20) NOT NULL,
  CONSTRAINT chk_studyPacks_targetRole
    CHECK (targetRole IN ('NORMAL_USER', 'TEACHER', 'ADMIN', 'PREMIUM_USER')),
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deletedAt TIMESTAMPTZ
);

-- ===========================
-- ORDERS (PACK PURCHASES)
-- ===========================
CREATE TABLE orders (
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

CREATE INDEX idx_orders_user ON orders(userId);
CREATE INDEX idx_orders_pack ON orders(packId);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_dates ON orders(startedAt, expiresAt);

-- ===========================
-- TRANSACTIONS
-- ===========================
CREATE TABLE transactions (
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

CREATE INDEX idx_transactions_purchase ON transactions(orderId);
CREATE INDEX idx_transactions_status ON transactions(status);

CREATE UNIQUE INDEX uq_transactions_provider_txnid
  ON transactions (COALESCE(provider, '~'), COALESCE(providerTxnId, '~'))
  WHERE providerTxnId IS NOT NULL;

-- ===========================
-- CLASSES (LỚP HỌC)
-- ===========================
CREATE TABLE classes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    ownerId INTEGER REFERENCES users(id) ON DELETE SET NULL,
    inviteCode VARCHAR(10) UNIQUE,  -- ✅ KEPT for inviting students
    "isPublic" BOOLEAN NOT NULL DEFAULT false,  -- ✅ WITH QUOTES
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_classes_invite_code ON classes(inviteCode);
CREATE INDEX idx_classes_owner ON classes(ownerId);
CREATE INDEX idx_classes_isPublic ON classes("isPublic");

-- ===========================
-- CLASS MEMBERS (THÀNH VIÊN LỚP HỌC)
-- ===========================

CREATE TABLE "classMembers" (
    "classId" INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "role" VARCHAR(50) NOT NULL DEFAULT 'STUDENT'
        CHECK ("role" IN ('STUDENT', 'TEACHER', 'CO_TEACHER')),
    "joinedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY ("classId", "userId")
);

CREATE INDEX "idx_class_members_user" ON "classMembers"("userId");
CREATE INDEX "idx_class_members_class" ON "classMembers"("classId");

-- ===========================
-- CATEGORIES (BỘ TỪ VỰNG/HỌC PHẦN)
-- ✅ ONE-TO-MANY: 1 category chỉ thuộc tối đa 1 class
-- ✅ INDEPENDENT: có thể không thuộc class nào ("classId" NULL)
-- ===========================
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    isSystem BOOLEAN NOT NULL DEFAULT FALSE,
    ownerUserId INTEGER REFERENCES users(id) ON DELETE CASCADE,
    "classId" INTEGER REFERENCES classes(id) ON DELETE SET NULL,  -- ✅ WITH QUOTES!
    visibility VARCHAR(30) NOT NULL DEFAULT 'PRIVATE'
        CHECK (visibility IN ('PUBLIC', 'PRIVATE', 'PASSWORD_PROTECTED', 'CLASS_ONLY')),
    sharePassword VARCHAR(255),
    shareToken VARCHAR(32) UNIQUE,
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deletedAt TIMESTAMPTZ
);

CREATE UNIQUE INDEX uq_categories_share_token ON categories(shareToken);
CREATE INDEX idx_categories_owner ON categories(ownerUserId);
CREATE INDEX idx_categories_class ON categories("classId");  -- ✅ WITH QUOTES!
CREATE INDEX idx_categories_visibility ON categories(visibility);
CREATE INDEX idx_categories_system ON categories(isSystem);

-- ===========================
-- USER SAVED CATEGORIES (CHỦ ĐỀ ĐÃ LƯU)
-- ✅ Normal user có thể lưu chủ đề yêu thích
-- ===========================
CREATE TABLE userSavedCategories (
    userId INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    categoryId INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    savedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (userId, categoryId)
);

CREATE INDEX idx_user_saved_categories_user ON userSavedCategories(userId);
CREATE INDEX idx_user_saved_categories_category ON userSavedCategories(categoryId);

-- ===========================
-- FLASHCARDS (THẺ HỌC)
-- ===========================
CREATE TABLE flashcards (
  id SERIAL PRIMARY KEY,
  term VARCHAR(255) NOT NULL,
  partOfSpeech VARCHAR(50),
  phonetic VARCHAR(100),
  imageUrl TEXT,
  meaning TEXT NOT NULL,
  categoryId INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  ttsUrl TEXT,
  createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_flashcards_category ON flashcards(categoryId);
CREATE INDEX idx_flashcards_term ON flashcards(term);

-- ===========================
-- SEED DATA
-- ===========================

-- ============ USERS ============
INSERT INTO users (email, fullName, passwordHash, status, dob, role, isBlocked) VALUES
('teacher@example.com', 'Nguyễn Văn Giáo', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1985-05-15', 'TEACHER', FALSE),
('ly@gmail.com', 'Trần Thị Ly', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2003-06-12', 'NORMAL_USER', FALSE),
('admin@example.com', 'Admin System', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1990-01-01', 'ADMIN', FALSE),
('blocked@example.com', 'Người Dùng Bị Khóa', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1999-03-15', 'NORMAL_USER', TRUE),
('premium@example.com', 'Nguyễn Premium', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2001-08-20', 'PREMIUM_USER', FALSE),
('student1@example.com', 'Lê Văn Học', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2005-03-10', 'NORMAL_USER', FALSE),
('student2@example.com', 'Phạm Thị Minh', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2004-11-25', 'NORMAL_USER', FALSE),
('teacher2@example.com', 'Hoàng Văn Dạy', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1988-07-20', 'TEACHER', FALSE);

-- ============ POLICIES ============
INSERT INTO policies (title, body, status) VALUES
('Điều khoản sử dụng', 'Quy định về việc tạo tài khoản, bảo mật mật khẩu...', 'ACTIVE'),
('Chính sách quyền riêng tư', 'Mô tả loại dữ liệu thu thập...', 'ACTIVE'),
('Chính sách cookie', 'Hệ thống sử dụng cookie...', 'ACTIVE'),
('Nguyên tắc cộng đồng', 'Nghiêm cấm nội dung thù hằn...', 'ACTIVE'),
('Chính sách bảo mật hệ thống', 'Hệ thống áp dụng mã hóa...', 'ACTIVE'),
('Điều khoản thanh toán & hoàn tiền', 'Thanh toán được xử lý...', 'ACTIVE'),
('Chính sách lưu trữ & xóa dữ liệu', 'Dữ liệu người dùng được xóa mềm...', 'DRAFT'),
('Chính sách phiên bản beta', 'Các tính năng beta có thể thay đổi...', 'INACTIVE');

-- ============ STUDY PACKS ============
INSERT INTO studyPacks (name, description, price, durationDays, targetRole) VALUES
('Basic 30 ngày', 'Gói cơ bản: học không giới hạn...', 159000, 30, 'NORMAL_USER'),
('Pro 30 ngày', 'Gói Pro: Mở khóa tính năng AI...', 239000, 30, 'NORMAL_USER'),
('Pro 1 năm', 'Gói Pro cả năm...', 1990000, 365, 'NORMAL_USER'),
('Teacher Premium 30 ngày', 'Gói Premium dành cho giáo viên...', 399000, 30, 'TEACHER'),
('Teacher Premium 1 năm', 'Gói Premium giáo viên cả năm...', 2399000, 365, 'TEACHER'),
('Premium User 30 ngày', 'Gói nâng cấp Premium...', 299000, 30, 'PREMIUM_USER'),
('Premium User 1 năm', 'Gói Premium User cả năm...', 2299000, 365, 'PREMIUM_USER');

-- ============ ORDERS ============
INSERT INTO orders (userId, packId, priceAtPurchase, status, startedAt, expiresAt) VALUES
(1, 4, 399000, 'PAID', NOW() - INTERVAL '10 days', NOW() + INTERVAL '20 days'),
(2, 2, 239000, 'PAID', NOW() - INTERVAL '5 days', NOW() + INTERVAL '25 days'),
(5, 7, 2299000, 'PAID', NOW() - INTERVAL '30 days', NOW() + INTERVAL '335 days'),
(6, 1, 159000, 'PENDING', NOW(), NOW() + INTERVAL '30 days');

-- ============ TRANSACTIONS ============
INSERT INTO transactions (orderId, amount, provider, method, providerTxnId, status, message) VALUES
(1, 399000, 'VNPay', 'BANK_CARD', 'VNPAY-20251201-001', 'SUCCEEDED', 'Thanh toán thành công'),
(2, 239000, 'MoMo', 'WALLET', 'MOMO-20251201-002', 'SUCCEEDED', 'Thanh toán thành công'),
(3, 2299000, 'VNPay', 'BANK_CARD', 'VNPAY-20251201-003', 'SUCCEEDED', 'Thanh toán thành công'),
(4, 159000, 'VNPay', 'BANK_CARD', 'VNPAY-20251201-004', 'INIT', 'Đang chờ xử lý');

-- ============ CLASSES ============
INSERT INTO classes (name, description, ownerId, inviteCode, "isPublic") VALUES
('TOEIC A1 - Cơ bản', 'Lớp luyện thi TOEIC từ 0 đến 450 điểm', 1, 'TOEIC24A', false),
('IELTS 6.5+ Online', 'Khóa IELTS trực tuyến', 1, 'IELTS65', false),
('Giao tiếp Tiếng Anh 101', 'Lớp giao tiếp cơ bản', 1, 'SPEAK101', true),
('Business English', 'Tiếng Anh thương mại', 1, 'BIZENG01', false),
('TOEFL iBT 90+', 'Khóa luyện thi TOEFL', 8, 'TOEFL90', false),
('English for Kids', 'Lớp tiếng Anh cho trẻ em', 8, 'KIDS2024', true);

-- ============ CLASS MEMBERS ============
INSERT INTO "classMembers" ("classId", "userId", "role", "joinedAt") VALUES
(1, 1, 'TEACHER', NOW() - INTERVAL '30 days'),
(1, 2, 'STUDENT', NOW() - INTERVAL '25 days'),
(1, 6, 'STUDENT', NOW() - INTERVAL '20 days'),
(2, 1, 'TEACHER', NOW() - INTERVAL '30 days'),
(2, 2, 'STUDENT', NOW() - INTERVAL '25 days'),
(2, 7, 'STUDENT', NOW() - INTERVAL '22 days'),
(3, 1, 'TEACHER', NOW() - INTERVAL '30 days'),
(3, 6, 'STUDENT', NOW() - INTERVAL '20 days'),
(3, 7, 'STUDENT', NOW() - INTERVAL '18 days'),
(4, 1, 'TEACHER', NOW() - INTERVAL '15 days'),
(4, 5, 'STUDENT', NOW() - INTERVAL '14 days'),
(5, 8, 'TEACHER', NOW() - INTERVAL '20 days'),
(5, 2, 'STUDENT', NOW() - INTERVAL '15 days'),
(6, 8, 'TEACHER', NOW() - INTERVAL '10 days'),
(6, 6, 'STUDENT', NOW() - INTERVAL '8 days'),
(6, 7, 'STUDENT', NOW() - INTERVAL '8 days');

-- ============ CATEGORIES ============
-- ✅ ONE-TO-MANY: 1 category chỉ thuộc tối đa 1 class
-- ✅ INDEPENDENT: "classId" có thể NULL (chưa gán vào class nào)
-- ✅ PUBLIC: Teacher/Premium có thể share

INSERT INTO categories (name, isSystem, ownerUserId, "classId", visibility, shareToken, createdAt) VALUES
-- System categories (công khai, không thuộc class cụ thể)
('Default English Words', TRUE, NULL, NULL, 'PUBLIC', 'tok_sys_default_words', NOW() - INTERVAL '90 days'),
('Common Phrases', TRUE, NULL, NULL, 'PUBLIC', 'tok_sys_phrases', NOW() - INTERVAL '90 days'),

-- Teacher categories IN classes (đã gán vào class)
('TOEIC Basic Vocabulary', FALSE, 1, 1, 'PUBLIC', 'tok_toeic_basic_123', NOW() - INTERVAL '30 days'),
('TOEIC Part 5 Grammar', FALSE, 1, 1, 'PUBLIC', 'tok_toeic_p5_456', NOW() - INTERVAL '28 days'),
('IELTS Academic Words', FALSE, 1, 2, 'PUBLIC', 'tok_ielts_435', NOW() - INTERVAL '30 days'),
('Business Email Templates', FALSE, 1, 4, 'PUBLIC', 'tok_biz_email_789', NOW() - INTERVAL '20 days'),

-- Teacher categories NOT IN class yet (độc lập, có thể add vào class sau)
('Advanced Grammar', FALSE, 1, NULL, 'PUBLIC', 'tok_advanced_grammar', NOW() - INTERVAL '25 days'),

-- Premium user categories (PUBLIC, chưa trong class)
('100 Common Verbs', FALSE, 5, NULL, 'PUBLIC', 'tok_verb100_992', NOW() - INTERVAL '25 days'),
('Advanced Idioms', FALSE, 5, NULL, 'PUBLIC', 'tok_premium_idioms_444', NOW() - INTERVAL '30 days'),

-- Normal user categories (PRIVATE, có thể được lưu bởi ai đó)
('Animals For Kids', FALSE, 2, NULL, 'PRIVATE', 'tok_animals_556', NOW() - INTERVAL '25 days'),
('My Personal Words', FALSE, 2, NULL, 'PRIVATE', 'tok_ly_personal_111', NOW() - INTERVAL '15 days'),

-- Teacher2 categories IN class
('TOEFL Reading Vocabulary', FALSE, 8, 5, 'PUBLIC', 'tok_toefl_read_333', NOW() - INTERVAL '20 days'),
('Kids Colors & Shapes', FALSE, 8, 6, 'PUBLIC', 'tok_kids_colors_222', NOW() - INTERVAL '10 days');

-- ============ USER SAVED CATEGORIES ============
-- ✅ Normal user có thể lưu chủ đề yêu thích
INSERT INTO userSavedCategories (userId, categoryId, savedAt) VALUES
-- User #2 (Ly - normal user) lưu categories
(2, 8, NOW() - INTERVAL '25 days'),   -- 100 Common Verbs
(2, 9, NOW() - INTERVAL '20 days'),   -- Advanced Idioms
(2, 3, NOW() - INTERVAL '18 days'),   -- TOEIC Basic Vocab

-- User #5 (premium) lưu
(5, 6, NOW() - INTERVAL '28 days'),   -- Business Email Templates
(5, 3, NOW() - INTERVAL '30 days'),   -- TOEIC Basic Vocab

-- User #6 (student1) lưu
(6, 3, NOW() - INTERVAL '20 days'),   -- TOEIC Basic Vocab
(6, 8, NOW() - INTERVAL '18 days'),   -- 100 Common Verbs

-- User #7 (student2) lưu
(7, 10, NOW() - INTERVAL '18 days');  -- Animals For Kids

-- ============ FLASHCARDS ============
-- Category #1: Default English Words
INSERT INTO flashcards (term, partOfSpeech, phonetic, meaning, categoryId) VALUES
('hello', 'interjection', '/həˈloʊ/', 'xin chào', 1),
('goodbye', 'interjection', '/ˌɡʊdˈbaɪ/', 'tạm biệt', 1),
('please', 'adverb', '/pliːz/', 'làm ơn', 1),
('thank you', 'phrase', '/θæŋk juː/', 'cảm ơn', 1);

-- Category #2: Common Phrases
INSERT INTO flashcards (term, meaning, categoryId) VALUES
('How are you?', 'Bạn khỏe không?', 2),
('Nice to meet you', 'Rất vui được gặp bạn', 2),
('See you later', 'Hẹn gặp lại', 2);

-- Category #3: TOEIC Basic Vocabulary (in class 1)
INSERT INTO flashcards (term, partOfSpeech, phonetic, meaning, categoryId) VALUES
('schedule', 'noun', '/ˈskedʒ.uːl/', 'lịch trình', 3),
('conference', 'noun', '/ˈkɒn.fər.əns/', 'hội nghị', 3),
('arrive', 'verb', '/əˈraɪv/', 'đến nơi', 3),
('appointment', 'noun', '/əˈpɔɪnt.mənt/', 'cuộc hẹn', 3),
('deadline', 'noun', '/ˈded.laɪn/', 'hạn chót', 3);

-- Category #8: 100 Common Verbs (PUBLIC, not in class yet)
INSERT INTO flashcards (term, partOfSpeech, phonetic, meaning, categoryId) VALUES
('run', 'verb', '/rʌn/', 'chạy', 8),
('speak', 'verb', '/spiːk/', 'nói', 8),
('learn', 'verb', '/lɜːrn/', 'học', 8),
('think', 'verb', '/θɪŋk/', 'nghĩ', 8),
('write', 'verb', '/raɪt/', 'viết', 8);

-- Category #10: Animals For Kids (PRIVATE)
INSERT INTO flashcards (term, partOfSpeech, meaning, categoryId, imageUrl) VALUES
('cat', 'noun', 'con mèo', 10, 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba'),
('dog', 'noun', 'con chó', 10, 'https://images.unsplash.com/photo-1543466835-00a7907e9de1'),
('bird', 'noun', 'con chim', 10, 'https://images.unsplash.com/photo-1444464666168-49d633b86797');

-- ===========================
-- VERIFICATION QUERIES
-- ===========================
SELECT 'Users' as table_name, COUNT(*) as count FROM users
UNION ALL SELECT 'Classes', COUNT(*) FROM classes
UNION ALL SELECT 'Categories', COUNT(*) FROM categories
UNION ALL SELECT 'Categories IN classes', COUNT(*) FROM categories WHERE "classId" IS NOT NULL
UNION ALL SELECT 'Categories INDEPENDENT', COUNT(*) FROM categories WHERE "classId" IS NULL
UNION ALL SELECT 'Flashcards', COUNT(*) FROM flashcards
UNION ALL SELECT 'User Saved', COUNT(*) FROM userSavedCategories;

-- Check ONE-TO-MANY: Mỗi class có bao nhiêu categories
SELECT 
    c.id,
    c.name as class_name,
    COUNT(cat.id) as category_count
FROM classes c
LEFT JOIN categories cat ON c.id = cat."classId"
GROUP BY c.id, c.name
ORDER BY c.id;

-- Check INDEPENDENT: Categories chưa gán vào class nào
SELECT 
    id,
    name,
    visibility,
    CASE 
        WHEN isSystem THEN 'SYSTEM'
        WHEN ownerUserId IN (SELECT id FROM users WHERE role='TEACHER') THEN 'TEACHER'
        WHEN ownerUserId IN (SELECT id FROM users WHERE role='PREMIUM_USER') THEN 'PREMIUM'
        ELSE 'NORMAL_USER'
    END as owner_type
FROM categories
WHERE "classId" IS NULL
ORDER BY visibility, id;

-- ===========================
-- SUCCESS MESSAGE
-- ===========================
DO $$
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ ONE-TO-MANY WITH INDEPENDENT CATEGORIES DEPLOYED!';
    RAISE NOTICE '════════════════════════════════════════════════════════';
    RAISE NOTICE 'Architecture: ONE-TO-MANY but Categories can be independent';
    RAISE NOTICE '';
    RAISE NOTICE '🌟 KEY FEATURES:';
    RAISE NOTICE '  ✅ Categories INDEPENDENT ("classId" can be NULL)';
    RAISE NOTICE '  ✅ 1 Category → 0 or 1 Class (ONE-TO-MANY)';
    RAISE NOTICE '  ✅ 1 Class → Many Categories';
    RAISE NOTICE '  ✅ UserSavedCategories (users can save favorites)';
    RAISE NOTICE '  ✅ Teacher/Premium can share PUBLIC categories';
    RAISE NOTICE '  ✅ inviteCode kept for student invitations';
    RAISE NOTICE '  ✅ "classId" WITH QUOTES (PostgreSQL case-sensitive fix)';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Data Summary:';
    RAISE NOTICE '  - 8 Users';
    RAISE NOTICE '  - 6 Classes (with inviteCode)';
    RAISE NOTICE '  - 13 Categories (7 in classes, 6 independent)';
    RAISE NOTICE '  - 7 User Saved Categories';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Category Distribution:';
    RAISE NOTICE '  - IN classes: 7 categories';
    RAISE NOTICE '  - INDEPENDENT (not in any class): 6 categories';
    RAISE NOTICE '  - Can be added to class later!';
    RAISE NOTICE '════════════════════════════════════════════════════════';
END $$;