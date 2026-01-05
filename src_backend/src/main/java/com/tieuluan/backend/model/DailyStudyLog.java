package com.tieuluan.backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Entity lưu log học tập hàng ngày
 * ✅ FIX: Thêm escaped quotes cho tên bảng và columns để PostgreSQL nhận diện đúng case
 */
@Entity
@Table(name = "\"dailyStudyLogs\"",
        uniqueConstraints = @UniqueConstraint(columnNames = {"userId", "studyDate"}))
public class DailyStudyLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "\"userId\"", nullable = false)
    private Integer userId;

    @Column(name = "\"studyDate\"", nullable = false)
    private LocalDate studyDate;

    @Column(name = "\"cardsStudied\"", nullable = false)
    private Integer cardsStudied = 0;

    @Column(name = "\"minutesSpent\"", nullable = false)
    private Integer minutesSpent = 0;

    @Column(name = "\"sessionsCount\"", nullable = false)
    private Integer sessionsCount = 0;

    // ==================== CONSTRUCTORS ====================

    public DailyStudyLog() {}

    public DailyStudyLog(Integer userId, LocalDate studyDate) {
        this.userId = userId;
        this.studyDate = studyDate;
    }

    // ==================== GETTERS & SETTERS ====================

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public LocalDate getStudyDate() { return studyDate; }
    public void setStudyDate(LocalDate studyDate) { this.studyDate = studyDate; }

    public Integer getCardsStudied() { return cardsStudied; }
    public void setCardsStudied(Integer cardsStudied) { this.cardsStudied = cardsStudied; }

    public Integer getMinutesSpent() { return minutesSpent; }
    public void setMinutesSpent(Integer minutesSpent) { this.minutesSpent = minutesSpent; }

    public Integer getSessionsCount() { return sessionsCount; }
    public void setSessionsCount(Integer sessionsCount) { this.sessionsCount = sessionsCount; }

    // ==================== HELPER METHODS ====================

    /**
     * Thêm thẻ đã học
     */
    public void addCardsStudied(int count) {
        this.cardsStudied += count;
    }

    /**
     * Thêm thời gian học (phút)
     */
    public void addMinutesSpent(int minutes) {
        this.minutesSpent += minutes;
    }

    /**
     * Tăng số phiên học
     */
    public void incrementSessions() {
        this.sessionsCount++;
    }
}