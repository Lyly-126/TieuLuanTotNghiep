package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.QuizResult;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 🎯 Quiz DTOs - Data Transfer Objects cho chức năng Quiz
 */
public class QuizDTO {

    // ===== REQUEST DTOs =====

    /**
     * Request tạo quiz mới
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class GenerateQuizRequest {
        private Integer categoryId;
        private QuizResult.QuizType quizType;      // Loại quiz
        private QuizResult.DifficultyLevel difficulty; // Độ khó (AUTO = theo tuổi)
        private Integer numberOfQuestions;          // Số câu hỏi (mặc định: 10)
        private List<String> skillFocus;           // ["LISTENING", "READING", "WRITING"]
        private Boolean includeImages;             // Có dùng hình ảnh không
        private Integer timeLimitSeconds;          // Giới hạn thời gian (0 = không giới hạn)
    }

    /**
     * Request submit câu trả lời
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubmitAnswerRequest {
        private Long questionId;
        private String userAnswer;
        private Integer timeSpentSeconds;
    }

    /**
     * Request submit toàn bộ quiz
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubmitQuizRequest {
        private Integer categoryId;
        private QuizResult.QuizType quizType;
        private QuizResult.DifficultyLevel difficulty;
        private List<QuestionAnswerDTO> answers;
        private Integer totalTimeSeconds;
    }

    /**
     * DTO cho câu trả lời của một câu hỏi
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuestionAnswerDTO {
        private Integer questionIndex;
        private Integer flashcardId;
        private String questionType;        // MULTIPLE_CHOICE, FILL_BLANK, etc.
        private String skillType;           // LISTENING, READING, WRITING
        private String userAnswer;
        private String correctAnswer;
        private Boolean isCorrect;
        private Integer timeSpentSeconds;
    }

    // ===== RESPONSE DTOs =====

    /**
     * Response chứa quiz đã generate
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class QuizResponse {
        private Integer categoryId;
        private String categoryName;
        private QuizResult.QuizType quizType;
        private QuizResult.DifficultyLevel difficulty;
        private Integer totalQuestions;
        private Integer timeLimitSeconds;
        private List<QuizQuestionDTO> questions;
        private UserAgeGroup userAgeGroup;  // Nhóm tuổi của user
    }

    /**
     * DTO cho một câu hỏi quiz
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class QuizQuestionDTO {
        private Integer index;
        private Integer flashcardId;
        private String questionType;        // Loại câu hỏi
        private String skillType;           // Kỹ năng: LISTENING, READING, WRITING
        private String question;            // Câu hỏi hiển thị
        private String hint;                // Gợi ý (nếu có)
        private List<String> options;       // Đáp án (cho trắc nghiệm)
        private String correctAnswer;       // Đáp án đúng (chỉ gửi khi submit)
        private String audioUrl;            // URL audio (cho câu nghe)
        private String imageUrl;            // URL hình ảnh
        private String phonetic;            // Phiên âm
        private Integer points;             // Điểm của câu hỏi
        private String word;                // Từ vựng gốc
        private String meaning;             // Nghĩa
    }

    /**
     * Response sau khi submit quiz
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class QuizResultResponse {
        private Long resultId;
        private Integer categoryId;
        private String categoryName;
        private QuizResult.QuizType quizType;
        private QuizResult.DifficultyLevel difficulty;

        // Kết quả tổng
        private Integer totalQuestions;
        private Integer correctAnswers;
        private Integer wrongAnswers;
        private Integer skippedQuestions;
        private Double score;               // Phần trăm (0-100)
        private Integer totalTimeSeconds;
        private Boolean passed;
        private String grade;               // Xếp loại

        // Kết quả theo kỹ năng
        private SkillScoreDTO skillScores;

        // Chi tiết từng câu
        private List<QuestionResultDTO> questionResults;

        // So sánh với lần trước
        private Double previousScore;
        private Double improvement;         // % cải thiện

        // Đề xuất
        private List<String> recommendations;

        private LocalDateTime completedAt;
    }

    /**
     * DTO điểm theo kỹ năng
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SkillScoreDTO {
        private Double listeningScore;
        private Integer listeningCorrect;
        private Integer listeningTotal;

        private Double readingScore;
        private Integer readingCorrect;
        private Integer readingTotal;

        private Double writingScore;
        private Integer writingCorrect;
        private Integer writingTotal;
    }

    /**
     * DTO kết quả từng câu hỏi
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class QuestionResultDTO {
        private Integer index;
        private Integer flashcardId;
        private String questionType;
        private String skillType;
        private String question;
        private String userAnswer;
        private String correctAnswer;
        private Boolean isCorrect;
        private Integer timeSpent;
        private String word;
        private String meaning;
        private String explanation;         // Giải thích (nếu sai)
    }

    /**
     * DTO thống kê quiz của user
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UserQuizStatsDTO {
        private Integer userId;
        private Integer totalQuizzes;
        private Integer totalQuestions;
        private Integer totalCorrect;
        private Double overallAccuracy;
        private Double averageScore;
        private Double highestScore;
        private Integer passedQuizzes;
        private Integer failedQuizzes;

        // Điểm trung bình theo kỹ năng
        private Double avgListeningScore;
        private Double avgReadingScore;
        private Double avgWritingScore;

        // Theo thời gian
        private Integer quizzesToday;
        private Integer quizzesThisWeek;

        // Tiến bộ
        private Double weeklyImprovement;

        // History gần nhất
        private List<QuizHistoryItemDTO> recentHistory;
    }

    /**
     * DTO item lịch sử quiz
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class QuizHistoryItemDTO {
        private Long resultId;
        private Integer categoryId;
        private String categoryName;
        private QuizResult.QuizType quizType;
        private Double score;
        private Integer correctAnswers;
        private Integer totalQuestions;
        private Boolean passed;
        private String grade;
        private LocalDateTime completedAt;
    }

    /**
     * DTO thống kê quiz cho category
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CategoryQuizStatsDTO {
        private Integer categoryId;
        private String categoryName;
        private Integer totalAttempts;
        private Double averageScore;
        private Double highestScore;
        private Double latestScore;
        private Integer passCount;
        private Double passRate;
        private LocalDateTime lastAttemptAt;

        // Skill breakdown cho category
        private SkillScoreDTO averageSkillScores;
    }

    // ===== ENUMS =====

    /**
     * Nhóm tuổi người dùng
     */
    public enum UserAgeGroup {
        KIDS("Trẻ em", 0, 11),
        TEEN("Thiếu niên", 12, 17),
        ADULT("Người lớn", 18, 100);

        private final String label;
        private final int minAge;
        private final int maxAge;

        UserAgeGroup(String label, int minAge, int maxAge) {
            this.label = label;
            this.minAge = minAge;
            this.maxAge = maxAge;
        }

        public String getLabel() { return label; }
        public int getMinAge() { return minAge; }
        public int getMaxAge() { return maxAge; }

        public static UserAgeGroup fromAge(int age) {
            if (age < 12) return KIDS;
            if (age < 18) return TEEN;
            return ADULT;
        }
    }
}