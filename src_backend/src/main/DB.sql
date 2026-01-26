-- ============================================================
-- FLASHCARD APP DATABASE SCHEMA
-- Version: 1.0
-- ============================================================

-- ===========================
-- 1. RESET DATABASE
-- ===========================
DROP TABLE IF EXISTS "categoryReminders" CASCADE;
DROP TABLE IF EXISTS "quizResults" CASCADE;
DROP TABLE IF EXISTS "dailyStudyLogs" CASCADE;
DROP TABLE IF EXISTS "studyStreaks" CASCADE;
DROP TABLE IF EXISTS "studySessions" CASCADE;
DROP TABLE IF EXISTS "studyProgress" CASCADE;
DROP TABLE IF EXISTS flashcards CASCADE;
DROP TABLE IF EXISTS userSavedCategories CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS "classMembers" CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS studyPacks CASCADE;
DROP TABLE IF EXISTS otpVerification CASCADE;
DROP TABLE IF EXISTS policies CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ===========================
-- 2. CORE TABLES
-- ===========================

-- 2.1 USERS
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

-- 2.2 OTP VERIFICATION
CREATE TABLE otpVerification (
    id SERIAL PRIMARY KEY,
    userId INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    otpCode VARCHAR(6) NOT NULL,
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiresAt TIMESTAMPTZ NOT NULL,
    isVerified BOOLEAN NOT NULL DEFAULT FALSE,
    verificationType VARCHAR(50) NOT NULL DEFAULT 'REGISTRATION'
);

-- 2.3 POLICIES
CREATE TABLE policies (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===========================
-- 3. PAYMENT TABLES
-- ===========================

-- 3.1 STUDY PACKS
CREATE TABLE studyPacks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
    durationDays INTEGER NOT NULL DEFAULT 30 CHECK (durationDays > 0),
    targetRole VARCHAR(20) NOT NULL,
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deletedAt TIMESTAMPTZ,
    CONSTRAINT chk_studyPacks_targetRole 
        CHECK (targetRole IN ('NORMAL_USER', 'TEACHER', 'ADMIN', 'PREMIUM_USER'))
);

-- 3.2 ORDERS
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    userId INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    packId INTEGER NOT NULL REFERENCES studyPacks(id) ON DELETE RESTRICT,
    priceAtPurchase NUMERIC(12,2) NOT NULL CHECK (priceAtPurchase >= 0),
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'PAID', 'CANCELED', 'REFUNDED', 'FAILED')),
    startedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expiresAt TIMESTAMPTZ,
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.3 TRANSACTIONS
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    orderId INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    provider VARCHAR(50),
    method VARCHAR(50),
    providerTxnId VARCHAR(120),
    status VARCHAR(30) NOT NULL DEFAULT 'INIT'
        CHECK (status IN ('INIT', 'SUCCEEDED', 'FAILED', 'REFUNDED')),
    rawPayload JSONB DEFAULT '{}'::jsonb,
    message TEXT,
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===========================
-- 4. CLASS TABLES
-- ===========================

-- 4.1 CLASSES
CREATE TABLE classes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    ownerId INTEGER REFERENCES users(id) ON DELETE SET NULL,
    inviteCode VARCHAR(10) UNIQUE,
    "isPublic" BOOLEAN NOT NULL DEFAULT FALSE,
    createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4.2 CLASS MEMBERS
CREATE TABLE "classMembers" (
    "classId" INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "role" VARCHAR(50) NOT NULL DEFAULT 'STUDENT'
        CHECK ("role" IN ('STUDENT', 'TEACHER', 'CO_TEACHER')),
    "status" VARCHAR(20) NOT NULL DEFAULT 'APPROVED'
        CHECK ("status" IN ('PENDING', 'APPROVED', 'REJECTED')),
    "joinedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY ("classId", "userId")
);

-- ===========================
-- 5. CATEGORY & FLASHCARD TABLES
-- ===========================

-- 5.1 CATEGORIES
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    isSystem BOOLEAN NOT NULL DEFAULT FALSE,
    ownerUserId INTEGER REFERENCES users(id) ON DELETE CASCADE,
    "classId" INTEGER REFERENCES classes(id) ON DELETE SET NULL,
    visibility VARCHAR(30) NOT NULL DEFAULT 'PRIVATE'
        CHECK (visibility IN ('PUBLIC', 'PRIVATE')),
    shareToken VARCHAR(32) UNIQUE
);

-- 5.2 USER SAVED CATEGORIES
CREATE TABLE userSavedCategories (
    userId INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    categoryId INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (userId, categoryId)
);

-- 5.3 FLASHCARDS
CREATE TABLE flashcards (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES users(id) ON DELETE SET NULL,
    word VARCHAR(255) NOT NULL,
    "partOfSpeech" VARCHAR(50),
    "partOfSpeechVi" VARCHAR(50),
    phonetic VARCHAR(100),
    "imageUrl" TEXT,
    meaning TEXT NOT NULL,
    "categoryId" INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    "ttsUrl" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5.4 DICTIONARY (table already exists separately)
CREATE TABLE dictionary (
    id integer NOT NULL,
    word text,
    part_of_speech text,
    part_of_speech_vi text,
    phonetic text,
    definitions text,
    meanings text,
    source text
);

-- ===========================
-- 6. STUDY PROGRESS TABLES
-- ===========================

-- 6.1 STUDY PROGRESS
CREATE TABLE "studyProgress" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "flashcardId" INTEGER NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    "categoryId" INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED'
        CHECK (status IN ('NOT_STARTED', 'LEARNING', 'MASTERED')),
    "correctCount" INTEGER NOT NULL DEFAULT 0,
    "incorrectCount" INTEGER NOT NULL DEFAULT 0,
    "lastStudiedAt" TIMESTAMPTZ,
    "nextReviewAt" TIMESTAMPTZ,
    difficulty INTEGER NOT NULL DEFAULT 3 CHECK (difficulty BETWEEN 1 AND 5),
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE("userId", "flashcardId")
);

-- 6.2 STUDY SESSIONS
CREATE TABLE "studySessions" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "categoryId" INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    "startedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "endedAt" TIMESTAMPTZ,
    "durationMinutes" INTEGER,
    "cardsStudied" INTEGER NOT NULL DEFAULT 0,
    "correctAnswers" INTEGER NOT NULL DEFAULT 0,
    "incorrectAnswers" INTEGER NOT NULL DEFAULT 0,
    "sessionType" VARCHAR(30) NOT NULL DEFAULT 'FLASHCARD'
        CHECK ("sessionType" IN ('FLASHCARD', 'QUIZ', 'REVIEW'))
);

-- 6.3 STUDY STREAKS
CREATE TABLE "studyStreaks" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    "currentStreak" INTEGER NOT NULL DEFAULT 0,
    "longestStreak" INTEGER NOT NULL DEFAULT 0,
    "lastStudyDate" DATE,
    "totalStudyDays" INTEGER NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6.4 DAILY STUDY LOGS
CREATE TABLE "dailyStudyLogs" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "studyDate" DATE NOT NULL,
    "cardsStudied" INTEGER NOT NULL DEFAULT 0,
    "minutesSpent" INTEGER NOT NULL DEFAULT 0,
    "sessionsCount" INTEGER NOT NULL DEFAULT 0,
    UNIQUE("userId", "studyDate")
);

-- ===========================
-- 7. QUIZ & REMINDER TABLES
-- ===========================

-- 7.1 QUIZ RESULTS
CREATE TABLE "quizResults" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "categoryId" INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    "quizType" VARCHAR(30) NOT NULL DEFAULT 'MIXED'
        CHECK ("quizType" IN (
            'MIXED', 'MULTIPLE_CHOICE', 'FILL_BLANK', 'LISTENING',
            'READING', 'WRITING', 'MATCHING', 'TRUE_FALSE', 'IMAGE_WORD'
        )),
    "difficultyLevel" VARCHAR(20) NOT NULL DEFAULT 'AUTO'
        CHECK ("difficultyLevel" IN ('KIDS', 'TEEN', 'ADULT', 'AUTO')),
    "totalQuestions" INTEGER NOT NULL CHECK ("totalQuestions" > 0),
    "correctAnswers" INTEGER NOT NULL DEFAULT 0 CHECK ("correctAnswers" >= 0),
    "wrongAnswers" INTEGER NOT NULL DEFAULT 0 CHECK ("wrongAnswers" >= 0),
    "skippedQuestions" INTEGER DEFAULT 0 CHECK ("skippedQuestions" >= 0),
    score DECIMAL(5,2) NOT NULL CHECK (score >= 0 AND score <= 100),
    "timeSpentSeconds" INTEGER,
    "listeningScore" DECIMAL(5,2) CHECK ("listeningScore" IS NULL OR ("listeningScore" >= 0 AND "listeningScore" <= 100)),
    "readingScore" DECIMAL(5,2) CHECK ("readingScore" IS NULL OR ("readingScore" >= 0 AND "readingScore" <= 100)),
    "writingScore" DECIMAL(5,2) CHECK ("writingScore" IS NULL OR ("writingScore" >= 0 AND "writingScore" <= 100)),
    "detailsJson" TEXT,
    "completedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7.2 CATEGORY REMINDERS
CREATE TABLE "categoryReminders" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "categoryId" INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    "reminderTime" TIME NOT NULL DEFAULT '20:00:00',
    "daysOfWeek" VARCHAR(7) NOT NULL DEFAULT '1111111',
    "isEnabled" BOOLEAN NOT NULL DEFAULT TRUE,
    "customMessage" VARCHAR(255),
    "fcmToken" TEXT,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE("userId", "categoryId")
);

-- ===========================
-- 8. INDEXES
-- ===========================

-- Drop existing indexes first
DROP INDEX IF EXISTS idx_otp_user_id;
DROP INDEX IF EXISTS idx_otp_code;
DROP INDEX IF EXISTS idx_orders_user;
DROP INDEX IF EXISTS idx_orders_pack;
DROP INDEX IF EXISTS idx_orders_status;
DROP INDEX IF EXISTS idx_orders_dates;
DROP INDEX IF EXISTS idx_transactions_order;
DROP INDEX IF EXISTS idx_transactions_status;
DROP INDEX IF EXISTS uq_transactions_provider_txnid;
DROP INDEX IF EXISTS idx_classes_owner;
DROP INDEX IF EXISTS idx_classes_isPublic;
DROP INDEX IF EXISTS idx_classMembers_user;
DROP INDEX IF EXISTS idx_classMembers_class;
DROP INDEX IF EXISTS idx_classMembers_status;
DROP INDEX IF EXISTS idx_classMembers_class_status;
DROP INDEX IF EXISTS idx_categories_owner;
DROP INDEX IF EXISTS idx_categories_class;
DROP INDEX IF EXISTS idx_categories_visibility;
DROP INDEX IF EXISTS idx_categories_system;
DROP INDEX IF EXISTS idx_userSavedCategories_user;
DROP INDEX IF EXISTS idx_userSavedCategories_category;
DROP INDEX IF EXISTS idx_flashcards_user;
DROP INDEX IF EXISTS idx_flashcards_category;
DROP INDEX IF EXISTS idx_flashcards_word;
DROP INDEX IF EXISTS idx_studyProgress_user;
DROP INDEX IF EXISTS idx_studyProgress_category;
DROP INDEX IF EXISTS idx_studyProgress_status;
DROP INDEX IF EXISTS idx_studyProgress_nextReview;
DROP INDEX IF EXISTS idx_studySessions_user;
DROP INDEX IF EXISTS idx_studySessions_started;
DROP INDEX IF EXISTS idx_studySessions_category;
DROP INDEX IF EXISTS idx_studyStreaks_user;
DROP INDEX IF EXISTS idx_studyStreaks_current;
DROP INDEX IF EXISTS idx_dailyStudyLogs_userDate;
DROP INDEX IF EXISTS idx_quizResults_user;
DROP INDEX IF EXISTS idx_quizResults_category;
DROP INDEX IF EXISTS idx_quizResults_userCategory;
DROP INDEX IF EXISTS idx_quizResults_completed;
DROP INDEX IF EXISTS idx_quizResults_score;
DROP INDEX IF EXISTS idx_quizResults_quizType;
DROP INDEX IF EXISTS idx_catReminders_user;
DROP INDEX IF EXISTS idx_catReminders_enabled;
DROP INDEX IF EXISTS idx_catReminders_time;

-- Users & OTP
CREATE INDEX idx_otp_user_id ON otpVerification(userId);
CREATE INDEX idx_otp_code ON otpVerification(otpCode);

-- Orders & Transactions
CREATE INDEX idx_orders_user ON orders(userId);
CREATE INDEX idx_orders_pack ON orders(packId);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_dates ON orders(startedAt, expiresAt);
CREATE INDEX idx_transactions_order ON transactions(orderId);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE UNIQUE INDEX uq_transactions_provider_txnid 
    ON transactions (COALESCE(provider, '~'), COALESCE(providerTxnId, '~'))
    WHERE providerTxnId IS NOT NULL;

-- Classes
CREATE INDEX idx_classes_owner ON classes(ownerId);
CREATE INDEX idx_classes_isPublic ON classes("isPublic");
CREATE INDEX idx_classMembers_user ON "classMembers"("userId");
CREATE INDEX idx_classMembers_class ON "classMembers"("classId");
CREATE INDEX idx_classMembers_status ON "classMembers"("status");
CREATE INDEX idx_classMembers_class_status ON "classMembers"("classId", "status");

-- Categories & Flashcards
CREATE INDEX idx_categories_owner ON categories(ownerUserId);
CREATE INDEX idx_categories_class ON categories("classId");
CREATE INDEX idx_categories_visibility ON categories(visibility);
CREATE INDEX idx_categories_system ON categories(isSystem);
CREATE INDEX idx_userSavedCategories_user ON userSavedCategories(userId);
CREATE INDEX idx_userSavedCategories_category ON userSavedCategories(categoryId);
CREATE INDEX idx_flashcards_user ON flashcards("userId");
CREATE INDEX idx_flashcards_category ON flashcards("categoryId");
CREATE INDEX idx_flashcards_word ON flashcards(word);

-- Study Progress
CREATE INDEX idx_studyProgress_user ON "studyProgress"("userId");
CREATE INDEX idx_studyProgress_category ON "studyProgress"("categoryId");
CREATE INDEX idx_studyProgress_status ON "studyProgress"(status);
CREATE INDEX idx_studyProgress_nextReview ON "studyProgress"("nextReviewAt");
CREATE INDEX idx_studySessions_user ON "studySessions"("userId");
CREATE INDEX idx_studySessions_started ON "studySessions"("startedAt");
CREATE INDEX idx_studySessions_category ON "studySessions"("categoryId");
CREATE INDEX idx_studyStreaks_user ON "studyStreaks"("userId");
CREATE INDEX idx_studyStreaks_current ON "studyStreaks"("currentStreak" DESC);
CREATE INDEX idx_dailyStudyLogs_userDate ON "dailyStudyLogs"("userId", "studyDate" DESC);

-- Quiz & Reminders
CREATE INDEX idx_quizResults_user ON "quizResults"("userId");
CREATE INDEX idx_quizResults_category ON "quizResults"("categoryId");
CREATE INDEX idx_quizResults_userCategory ON "quizResults"("userId", "categoryId");
CREATE INDEX idx_quizResults_completed ON "quizResults"("completedAt" DESC);
CREATE INDEX idx_quizResults_score ON "quizResults"(score);
CREATE INDEX idx_quizResults_quizType ON "quizResults"("quizType");
CREATE INDEX idx_catReminders_user ON "categoryReminders"("userId");
CREATE INDEX idx_catReminders_enabled ON "categoryReminders"("isEnabled") WHERE "isEnabled" = TRUE;
CREATE INDEX idx_catReminders_time ON "categoryReminders"("reminderTime");

-- ============================================================
-- 9. SEED DATA
-- ============================================================

-- 9.1 USERS
INSERT INTO users (email, fullName, passwordHash, status, dob, role, isBlocked) VALUES
('teacher@example.com', 'Nguyễn Văn Giáo', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1985-05-15', 'TEACHER', FALSE),
('ly@gmail.com', 'Trần Thị Ly', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2003-06-12', 'NORMAL_USER', FALSE),
('admin@example.com', 'Admin System', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1990-01-01', 'ADMIN', FALSE),
('blocked@example.com', 'Người Dùng Bị Khóa', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1999-03-15', 'NORMAL_USER', TRUE),
('premium@example.com', 'Nguyễn Premium', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2001-08-20', 'PREMIUM_USER', FALSE),
('student1@example.com', 'Lê Văn Học', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2005-03-10', 'NORMAL_USER', FALSE),
('student2@example.com', 'Phạm Thị Minh', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '2004-11-25', 'NORMAL_USER', FALSE),
('teacher2@example.com', 'Hoàng Văn Dạy', '$2a$12$557mTcg9Iqt8DMo03nROvOu6e0s9u4mf1Z2udG1Mv0YZmh/eVakzi', 'VERIFIED', '1988-07-20', 'TEACHER', FALSE);

-- 9.2 POLICIES
INSERT INTO policies (title, body, status) VALUES
('Điều khoản sử dụng', 'Quy định...', 'ACTIVE'),
('Chính sách quyền riêng tư', 'Mô tả...', 'ACTIVE'),
('Chính sách cookie', 'Hệ thống...', 'ACTIVE'),
('Nguyên tắc cộng đồng', 'Nghiêm cấm...', 'ACTIVE'),
('Chính sách bảo mật hệ thống', 'Hệ thống...', 'ACTIVE'),
('Điều khoản thanh toán & hoàn tiền', 'Thanh toán...', 'ACTIVE'),
('Chính sách lưu trữ & xóa dữ liệu', 'Xóa mềm...', 'DRAFT'),
('Chính sách phiên bản beta', 'Có thể thay đổi...', 'INACTIVE');

-- 9.3 STUDY PACKS
INSERT INTO studyPacks (name, description, price, durationDays, targetRole) VALUES
('Basic 30 ngày', 'Gói cơ bản...', 159000, 30, 'NORMAL_USER'),
('Pro 30 ngày', 'Gói Pro...', 239000, 30, 'NORMAL_USER'),
('Pro 1 năm', 'Cả năm...', 1990000, 365, 'NORMAL_USER'),
('Teacher Premium 30 ngày', 'Premium giáo viên...', 399000, 30, 'TEACHER'),
('Teacher Premium 1 năm', 'Premium giáo viên năm...', 2399000, 365, 'TEACHER'),
('Premium User 30 ngày', 'Nâng cấp...', 299000, 30, 'PREMIUM_USER'),
('Premium User 1 năm', 'Năm...', 2299000, 365, 'PREMIUM_USER');

-- 9.4 ORDERS
INSERT INTO orders (userId, packId, priceAtPurchase, status, startedAt, expiresAt) VALUES
(1, 4, 399000, 'PAID', NOW() - INTERVAL '10 days', NOW() + INTERVAL '20 days'),
(2, 2, 239000, 'PAID', NOW() - INTERVAL '5 days', NOW() + INTERVAL '25 days'),
(5, 7, 2299000, 'PAID', NOW() - INTERVAL '30 days', NOW() + INTERVAL '335 days'),
(6, 1, 159000, 'PENDING', NOW(), NOW() + INTERVAL '30 days');

-- 9.5 TRANSACTIONS
INSERT INTO transactions (orderId, amount, provider, method, providerTxnId, status, message) VALUES
(1, 399000, 'VNPay', 'BANK_CARD', 'VNPAY-20251201-001', 'SUCCEEDED', 'Thanh toán thành công'),
(2, 239000, 'MoMo', 'WALLET', 'MOMO-20251201-002', 'SUCCEEDED', 'Thanh toán thành công'),
(3, 2299000, 'VNPay', 'BANK_CARD', 'VNPAY-20251201-003', 'SUCCEEDED', 'Thanh toán thành công'),
(4, 159000, 'VNPay', 'BANK_CARD', 'VNPAY-20251201-004', 'INIT', 'Đang chờ xử lý');

-- 9.6 CLASSES
INSERT INTO classes (name, description, ownerId, inviteCode, "isPublic") VALUES
('TOEIC A1 - Cơ bản', 'Lớp luyện thi TOEIC từ 0 đến 450 điểm', 1, 'TOEIC24A', FALSE),
('IELTS 6.5+ Online', 'Khóa IELTS trực tuyến', 1, 'IELTS65', FALSE),
('Giao tiếp Tiếng Anh 101', 'Lớp giao tiếp cơ bản', 1, 'SPEAK101', TRUE),
('Business English', 'Tiếng Anh thương mại', 1, 'BIZENG01', FALSE),
('TOEFL iBT 90+', 'Khóa luyện thi TOEFL', 8, 'TOEFL90', FALSE),
('English for Kids', 'Lớp cho trẻ em', 8, 'KIDS2024', TRUE);

-- 9.7 CLASS MEMBERS
INSERT INTO "classMembers" ("classId", "userId", "role", "status", "joinedAt") VALUES
(1, 2, 'STUDENT', 'APPROVED', NOW() - INTERVAL '25 days'),
(1, 6, 'STUDENT', 'APPROVED', NOW() - INTERVAL '20 days'),
(2, 2, 'STUDENT', 'APPROVED', NOW() - INTERVAL '25 days'),
(2, 7, 'STUDENT', 'APPROVED', NOW() - INTERVAL '22 days'),
(3, 6, 'STUDENT', 'APPROVED', NOW() - INTERVAL '20 days'),
(3, 7, 'STUDENT', 'APPROVED', NOW() - INTERVAL '18 days'),
(4, 5, 'STUDENT', 'APPROVED', NOW() - INTERVAL '14 days'),
(4, 6, 'STUDENT', 'PENDING', NOW() - INTERVAL '2 days'),
(4, 7, 'STUDENT', 'PENDING', NOW() - INTERVAL '1 day'),
(5, 2, 'STUDENT', 'APPROVED', NOW() - INTERVAL '15 days'),
(5, 5, 'STUDENT', 'PENDING', NOW() - INTERVAL '3 days'),
(5, 6, 'STUDENT', 'PENDING', NOW() - INTERVAL '2 days'),
(6, 6, 'STUDENT', 'APPROVED', NOW() - INTERVAL '8 days'),
(6, 7, 'STUDENT', 'APPROVED', NOW() - INTERVAL '8 days');

-- 9.8 CATEGORIES
INSERT INTO categories (name, isSystem, ownerUserId, "classId", visibility, shareToken) VALUES
('Default English Words', TRUE, NULL, NULL, 'PUBLIC', 'tok_sys_default_words'),
('Common Phrases', TRUE, NULL, NULL, 'PUBLIC', 'tok_sys_phrases'),
('TOEIC Basic Vocabulary', FALSE, 1, 1, 'PUBLIC', 'tok_toeic_basic_123'),
('TOEIC Part 5 Grammar', FALSE, 1, 1, 'PUBLIC', 'tok_toeic_p5_456'),
('IELTS Academic Words', FALSE, 1, 2, 'PUBLIC', 'tok_ielts_435'),
('Business Email Templates', FALSE, 1, 4, 'PUBLIC', 'tok_biz_email_789'),
('Advanced Grammar', FALSE, 1, NULL, 'PUBLIC', 'tok_advanced_grammar'),
('100 Common Verbs', FALSE, 5, NULL, 'PUBLIC', 'tok_verb100_992'),
('Advanced Idioms', FALSE, 5, NULL, 'PUBLIC', 'tok_premium_idioms_444'),
('Animals For Kids', FALSE, 2, NULL, 'PRIVATE', 'tok_animals_556'),
('My Personal Words', FALSE, 2, NULL, 'PRIVATE', 'tok_ly_personal_111'),
('TOEFL Reading Vocabulary', FALSE, 8, 5, 'PUBLIC', 'tok_toefl_read_333'),
('Kids Colors & Shapes', FALSE, 8, 6, 'PUBLIC', 'tok_kids_colors_222');

-- 9.9 USER SAVED CATEGORIES
INSERT INTO userSavedCategories (userId, categoryId) VALUES
(2, 8), (2, 9), (2, 3),
(5, 6), (5, 3),
(6, 3), (6, 8),
(7, 10);

-- 9.10 FLASHCARDS
INSERT INTO flashcards ("userId", word, "partOfSpeech", "partOfSpeechVi", phonetic, meaning, "categoryId") VALUES
(3, 'hello', 'interjection', 'thán từ', '/həˈloʊ/', 'xin chào', 1),
(3, 'goodbye', 'interjection', 'thán từ', '/ˌɡʊdˈbaɪ/', 'tạm biệt', 1),
(3, 'please', 'adverb', 'trạng từ', '/pliːz/', 'làm ơn', 1),
(3, 'thank you', 'phrase', 'cụm từ', '/θæŋk juː/', 'cảm ơn', 1),
(3, 'How are you?', 'phrase', 'cụm từ', NULL, 'Bạn khỏe không?', 2),
(3, 'Nice to meet you', 'phrase', 'cụm từ', NULL, 'Rất vui được gặp bạn', 2),
(3, 'See you later', 'phrase', 'cụm từ', NULL, 'Hẹn gặp lại', 2),
(1, 'schedule', 'noun', 'danh từ', '/ˈskedʒ.uːl/', 'lịch trình', 3),
(1, 'conference', 'noun', 'danh từ', '/ˈkɒn.fər.əns/', 'hội nghị', 3),
(1, 'arrive', 'verb', 'động từ', '/əˈraɪv/', 'đến nơi', 3),
(1, 'appointment', 'noun', 'danh từ', '/əˈpɔɪnt.mənt/', 'cuộc hẹn', 3),
(1, 'deadline', 'noun', 'danh từ', '/ˈded.laɪn/', 'hạn chót', 3),
(5, 'run', 'verb', 'động từ', '/rʌn/', 'chạy', 8),
(5, 'speak', 'verb', 'động từ', '/spiːk/', 'nói', 8),
(5, 'learn', 'verb', 'động từ', '/lɜːrn/', 'học', 8),
(5, 'think', 'verb', 'động từ', '/θɪŋk/', 'nghĩ', 8),
(5, 'write', 'verb', 'động từ', '/raɪt/', 'viết', 8);

INSERT INTO flashcards ("userId", word, "partOfSpeech", "partOfSpeechVi", phonetic, meaning, "categoryId", "imageUrl") VALUES
(2, 'cat', 'noun', 'danh từ', '/kæt/', 'con mèo', 10, 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba'),
(2, 'dog', 'noun', 'danh từ', '/dɒɡ/', 'con chó', 10, 'https://images.unsplash.com/photo-1543466835-00a7907e9de1'),
(2, 'bird', 'noun', 'danh từ', '/bɜːrd/', 'con chim', 10, 'https://images.unsplash.com/photo-1444464666168-49d633b86797');

-- 9.11 STUDY STREAKS
INSERT INTO "studyStreaks" ("userId", "currentStreak", "longestStreak", "lastStudyDate", "totalStudyDays") VALUES
(2, 5, 12, CURRENT_DATE, 45),
(5, 15, 30, CURRENT_DATE, 120),
(6, 0, 7, CURRENT_DATE - 3, 20);

-- 9.12 DAILY STUDY LOGS (7 ngày gần đây cho user 2)
INSERT INTO "dailyStudyLogs" ("userId", "studyDate", "cardsStudied", "minutesSpent", "sessionsCount")
SELECT 2, CURRENT_DATE - i, 
       floor(random() * 30 + 10)::int,
       floor(random() * 30 + 5)::int,
       floor(random() * 3 + 1)::int
FROM generate_series(0, 6) AS i;

-- 9.13 STUDY PROGRESS (cho category 3 - TOEIC Basic, user 2)
INSERT INTO "studyProgress" ("userId", "flashcardId", "categoryId", status, "correctCount", "incorrectCount", "lastStudiedAt")
SELECT 2, f.id, 3,
       CASE 
           WHEN random() < 0.3 THEN 'MASTERED'
           WHEN random() < 0.6 THEN 'LEARNING'
           ELSE 'NOT_STARTED'
       END,
       floor(random() * 5)::int,
       floor(random() * 2)::int,
       NOW() - (random() * INTERVAL '7 days')
FROM flashcards f
WHERE f."categoryId" = 3;

-- 9.14 QUIZ RESULTS
INSERT INTO "quizResults" ("userId", "categoryId", "quizType", "difficultyLevel", "totalQuestions", "correctAnswers", "wrongAnswers", "skippedQuestions", score, "timeSpentSeconds", "listeningScore", "readingScore", "writingScore", "completedAt") VALUES
(2, 3, 'MIXED', 'TEEN', 10, 7, 2, 1, 70.00, 180, 80.00, 66.67, 60.00, NOW() - INTERVAL '5 days'),
(2, 3, 'MULTIPLE_CHOICE', 'TEEN', 10, 8, 2, 0, 80.00, 150, NULL, 80.00, NULL, NOW() - INTERVAL '3 days'),
(2, 3, 'LISTENING', 'TEEN', 10, 9, 1, 0, 90.00, 200, 90.00, NULL, NULL, NOW() - INTERVAL '1 day'),
(5, 8, 'MIXED', 'ADULT', 15, 12, 3, 0, 80.00, 300, 75.00, 85.00, 80.00, NOW() - INTERVAL '7 days'),
(5, 8, 'WRITING', 'ADULT', 10, 8, 2, 0, 80.00, 400, NULL, NULL, 80.00, NOW() - INTERVAL '4 days'),
(6, 3, 'MIXED', 'TEEN', 10, 5, 4, 1, 50.00, 250, 40.00, 60.00, 50.00, NOW() - INTERVAL '6 days'),
(6, 3, 'FILL_BLANK', 'TEEN', 10, 7, 3, 0, 70.00, 220, NULL, NULL, 70.00, NOW() - INTERVAL '2 days'),
(7, 10, 'IMAGE_WORD', 'KIDS', 5, 4, 1, 0, 80.00, 60, NULL, 80.00, NULL, NOW() - INTERVAL '4 days'),
(7, 10, 'MIXED', 'KIDS', 5, 5, 0, 0, 100.00, 50, 100.00, 100.00, 100.00, NOW() - INTERVAL '1 day');

-- ============================================================
-- END OF SCHEMA
-- ============================================================