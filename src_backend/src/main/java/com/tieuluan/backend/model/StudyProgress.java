package com.tieuluan.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity theo dõi tiến trình học từng flashcard của user
 */
@Entity
@Table(name = "\"studyProgress\"",
        uniqueConstraints = @UniqueConstraint(columnNames = {"userId", "flashcardId"}))
public class StudyProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "\"userId\"", nullable = false)
    private Integer userId;

    @Column(name = "\"flashcardId\"", nullable = false)
    private Integer flashcardId;

    @Column(name = "\"categoryId\"", nullable = false)
    private Integer categoryId;

    /**
     * Trạng thái: NOT_STARTED, LEARNING, MASTERED
     */
    @Column(nullable = false, length = 20)
    private String status = "NOT_STARTED";

    @Column(name = "\"correctCount\"", nullable = false)
    private Integer correctCount = 0;

    @Column(name = "\"incorrectCount\"", nullable = false)
    private Integer incorrectCount = 0;

    @Column(name = "\"lastStudiedAt\"")
    private LocalDateTime lastStudiedAt;

    @Column(name = "\"nextReviewAt\"")
    private LocalDateTime nextReviewAt;

    /**
     * Độ khó 1-5 (dựa trên số lần trả lời sai)
     */
    @Column(nullable = false)
    private Integer difficulty = 3;

    @Column(name = "\"createdAt\"", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "\"updatedAt\"", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // ===== Constructors =====

    public StudyProgress() {}

    public StudyProgress(Integer userId, Integer flashcardId, Integer categoryId) {
        this.userId = userId;
        this.flashcardId = flashcardId;
        this.categoryId = categoryId;
        this.status = "NOT_STARTED";
        this.correctCount = 0;
        this.incorrectCount = 0;
        this.difficulty = 3;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    // ===== Getters & Setters =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getFlashcardId() { return flashcardId; }
    public void setFlashcardId(Integer flashcardId) { this.flashcardId = flashcardId; }

    public Integer getCategoryId() { return categoryId; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getCorrectCount() { return correctCount; }
    public void setCorrectCount(Integer correctCount) { this.correctCount = correctCount; }

    public Integer getIncorrectCount() { return incorrectCount; }
    public void setIncorrectCount(Integer incorrectCount) { this.incorrectCount = incorrectCount; }

    public LocalDateTime getLastStudiedAt() { return lastStudiedAt; }
    public void setLastStudiedAt(LocalDateTime lastStudiedAt) { this.lastStudiedAt = lastStudiedAt; }

    public LocalDateTime getNextReviewAt() { return nextReviewAt; }
    public void setNextReviewAt(LocalDateTime nextReviewAt) { this.nextReviewAt = nextReviewAt; }

    public Integer getDifficulty() { return difficulty; }
    public void setDifficulty(Integer difficulty) { this.difficulty = difficulty; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    // ===== Helper Methods =====

    /**
     * Tính tỷ lệ đúng (0.0 - 1.0)
     */
    public double getAccuracyRate() {
        int total = correctCount + incorrectCount;
        if (total == 0) return 0.0;
        return (double) correctCount / total;
    }

    /**
     * Kiểm tra đã master chưa
     */
    public boolean isMastered() {
        return "MASTERED".equals(status);
    }

    /**
     * Kiểm tra đang học
     */
    public boolean isLearning() {
        return "LEARNING".equals(status);
    }

    /**
     * Cập nhật sau khi trả lời đúng
     */
    public void recordCorrect() {
        this.correctCount++;
        this.lastStudiedAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        updateStatus();
        calculateNextReview();
    }

    /**
     * Cập nhật sau khi trả lời sai
     */
    public void recordIncorrect() {
        this.incorrectCount++;
        this.lastStudiedAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        updateDifficulty();
        updateStatus();
        calculateNextReview();
    }

    /**
     * Cập nhật sau khi trả lời (generic method)
     */
    public void updateAfterAnswer(boolean isCorrect) {
        if (isCorrect) {
            recordCorrect();
        } else {
            recordIncorrect();
        }
    }

    private void updateStatus() {
        if (correctCount >= 5 && getAccuracyRate() >= 0.8) {
            this.status = "MASTERED";
        } else if (correctCount > 0 || incorrectCount > 0) {
            this.status = "LEARNING";
        }
    }

    private void updateDifficulty() {
        // Tăng difficulty nếu sai nhiều
        double accuracy = getAccuracyRate();
        if (accuracy < 0.3) {
            this.difficulty = 5;
        } else if (accuracy < 0.5) {
            this.difficulty = 4;
        } else if (accuracy < 0.7) {
            this.difficulty = 3;
        } else if (accuracy < 0.9) {
            this.difficulty = 2;
        } else {
            this.difficulty = 1;
        }
    }

    private void calculateNextReview() {
        // Spaced repetition: thời gian ôn tập dựa trên difficulty
        int daysUntilReview;
        switch (difficulty) {
            case 1: daysUntilReview = 7; break;    // Dễ: 7 ngày
            case 2: daysUntilReview = 3; break;    // Khá dễ: 3 ngày
            case 3: daysUntilReview = 1; break;    // Trung bình: 1 ngày
            case 4: daysUntilReview = 0; break;    // Khó: trong ngày
            case 5: daysUntilReview = 0; break;    // Rất khó: trong ngày
            default: daysUntilReview = 1;
        }
        this.nextReviewAt = LocalDateTime.now().plusDays(daysUntilReview);
    }

    @Override
    public String toString() {
        return "StudyProgress{" +
                "id=" + id +
                ", userId=" + userId +
                ", flashcardId=" + flashcardId +
                ", status='" + status + '\'' +
                ", correctCount=" + correctCount +
                ", incorrectCount=" + incorrectCount +
                '}';
    }
}