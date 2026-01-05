package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDateTime;

/**
 * 🎯 QuizResult Entity - Lưu kết quả kiểm tra
 *
 * Theo dõi kết quả quiz của người dùng cho mỗi category
 */
@Entity
@Table(name = "quiz_results")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class QuizResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Integer userId;

    @Column(name = "category_id", nullable = false)
    private Integer categoryId;

    // ===== THÔNG TIN QUIZ =====

    @Column(name = "quiz_type", nullable = false)
    @Enumerated(EnumType.STRING)
    private QuizType quizType;

    @Column(name = "difficulty_level", nullable = false)
    @Enumerated(EnumType.STRING)
    private DifficultyLevel difficultyLevel;

    // ===== KẾT QUẢ =====

    @Column(name = "total_questions", nullable = false)
    private Integer totalQuestions;

    @Column(name = "correct_answers", nullable = false)
    private Integer correctAnswers;

    @Column(name = "wrong_answers", nullable = false)
    private Integer wrongAnswers;

    // ✅ FIXED: Thêm @Builder.Default để giá trị mặc định hoạt động với @Builder
    @Column(name = "skipped_questions")
    @Builder.Default
    private Integer skippedQuestions = 0;

    @Column(name = "score", nullable = false)
    private Double score; // Tính theo phần trăm (0-100)

    @Column(name = "time_spent_seconds")
    private Integer timeSpentSeconds; // Thời gian làm bài (giây)

    // ===== SKILL BREAKDOWN =====

    @Column(name = "listening_score")
    private Double listeningScore;

    @Column(name = "reading_score")
    private Double readingScore;

    @Column(name = "writing_score")
    private Double writingScore;

    // ===== CHI TIẾT =====

    @Column(name = "details_json", columnDefinition = "TEXT")
    private String detailsJson; // JSON chứa chi tiết từng câu hỏi

    @Column(name = "completed_at", nullable = false)
    private LocalDateTime completedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    // ===== ENUMS =====

    public enum QuizType {
        MIXED,          // Hỗn hợp tất cả loại
        MULTIPLE_CHOICE,// Trắc nghiệm
        FILL_BLANK,     // Điền khuyết
        LISTENING,      // Nghe
        READING,        // Đọc hiểu
        WRITING,        // Viết
        MATCHING,       // Nối từ
        TRUE_FALSE,     // Đúng/Sai
        IMAGE_WORD      // Nhìn hình đoán từ
    }

    public enum DifficultyLevel {
        KIDS,       // Trẻ em (< 12 tuổi) - Dễ, nhiều hình ảnh
        TEEN,       // Thiếu niên (12-17) - Trung bình
        ADULT,      // Người lớn (18+) - Khó
        AUTO        // Tự động theo tuổi user
    }

    // ===== PrePersist =====

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (completedAt == null) {
            completedAt = LocalDateTime.now();
        }
        if (skippedQuestions == null) {
            skippedQuestions = 0;
        }
    }

    // ===== Helper Methods =====

    /**
     * Tính điểm trung bình các kỹ năng
     */
    public Double getAverageSkillScore() {
        double total = 0;
        int count = 0;

        if (listeningScore != null) {
            total += listeningScore;
            count++;
        }
        if (readingScore != null) {
            total += readingScore;
            count++;
        }
        if (writingScore != null) {
            total += writingScore;
            count++;
        }

        return count > 0 ? total / count : score;
    }

    /**
     * Kiểm tra đạt yêu cầu (>= 60%)
     */
    public boolean isPassed() {
        return score >= 60.0;
    }

    /**
     * Lấy xếp loại
     */
    public String getGrade() {
        if (score >= 90) return "Xuất sắc";
        if (score >= 80) return "Giỏi";
        if (score >= 70) return "Khá";
        if (score >= 60) return "Trung bình";
        if (score >= 50) return "Yếu";
        return "Cần cải thiện";
    }
}