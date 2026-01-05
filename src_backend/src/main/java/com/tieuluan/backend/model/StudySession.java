package com.tieuluan.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity lưu thông tin từng phiên học
 * ✅ FIX: Thêm escaped quotes cho tên bảng và columns để PostgreSQL nhận diện đúng case
 */
@Entity
@Table(name = "\"studySessions\"")
public class StudySession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "\"userId\"", nullable = false)
    private Integer userId;

    @Column(name = "\"categoryId\"")
    private Integer categoryId;

    @Column(name = "\"startedAt\"", nullable = false)
    private LocalDateTime startedAt = LocalDateTime.now();

    @Column(name = "\"endedAt\"")
    private LocalDateTime endedAt;

    @Column(name = "\"durationMinutes\"")
    private Integer durationMinutes;

    @Column(name = "\"cardsStudied\"", nullable = false)
    private Integer cardsStudied = 0;

    @Column(name = "\"correctAnswers\"", nullable = false)
    private Integer correctAnswers = 0;

    @Column(name = "\"incorrectAnswers\"", nullable = false)
    private Integer incorrectAnswers = 0;

    /**
     * Loại phiên học: FLASHCARD, QUIZ, REVIEW
     */
    @Column(name = "\"sessionType\"", nullable = false, length = 30)
    private String sessionType = "FLASHCARD";

    // ==================== CONSTRUCTORS ====================

    public StudySession() {}

    public StudySession(Integer userId, Integer categoryId, String sessionType) {
        this.userId = userId;
        this.categoryId = categoryId;
        this.sessionType = sessionType;
    }

    // ==================== GETTERS & SETTERS ====================

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getCategoryId() { return categoryId; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }

    public LocalDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(LocalDateTime startedAt) { this.startedAt = startedAt; }

    public LocalDateTime getEndedAt() { return endedAt; }
    public void setEndedAt(LocalDateTime endedAt) { this.endedAt = endedAt; }

    public Integer getDurationMinutes() { return durationMinutes; }
    public void setDurationMinutes(Integer durationMinutes) { this.durationMinutes = durationMinutes; }

    public Integer getCardsStudied() { return cardsStudied; }
    public void setCardsStudied(Integer cardsStudied) { this.cardsStudied = cardsStudied; }

    public Integer getCorrectAnswers() { return correctAnswers; }
    public void setCorrectAnswers(Integer correctAnswers) { this.correctAnswers = correctAnswers; }

    public Integer getIncorrectAnswers() { return incorrectAnswers; }
    public void setIncorrectAnswers(Integer incorrectAnswers) { this.incorrectAnswers = incorrectAnswers; }

    public String getSessionType() { return sessionType; }
    public void setSessionType(String sessionType) { this.sessionType = sessionType; }

    // ==================== HELPER METHODS ====================

    /**
     * Kết thúc phiên học
     */
    public void endSession() {
        this.endedAt = LocalDateTime.now();
        if (startedAt != null) {
            long minutes = java.time.Duration.between(startedAt, endedAt).toMinutes();
            this.durationMinutes = (int) minutes;
        }
    }

    /**
     * Ghi nhận trả lời đúng
     */
    public void recordCorrect() {
        this.correctAnswers++;
        this.cardsStudied++;
    }

    /**
     * Ghi nhận trả lời sai
     */
    public void recordIncorrect() {
        this.incorrectAnswers++;
        this.cardsStudied++;
    }

    /**
     * Tính tỷ lệ đúng
     */
    public double getAccuracyRate() {
        int total = correctAnswers + incorrectAnswers;
        if (total == 0) return 0.0;
        return (double) correctAnswers / total;
    }
}