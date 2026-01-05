package com.tieuluan.backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entity lưu trữ streak (chuỗi ngày học liên tục) của user
 * ✅ FIX: Thêm escaped quotes cho tên bảng và columns để PostgreSQL nhận diện đúng case
 */
@Entity
@Table(name = "\"studyStreaks\"")
public class StudyStreak {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "\"userId\"", nullable = false, unique = true)
    private Integer userId;

    /**
     * Streak hiện tại (số ngày liên tục)
     */
    @Column(name = "\"currentStreak\"", nullable = false)
    private Integer currentStreak = 0;

    /**
     * Streak dài nhất từng đạt được
     */
    @Column(name = "\"longestStreak\"", nullable = false)
    private Integer longestStreak = 0;

    /**
     * Ngày học gần nhất
     */
    @Column(name = "\"lastStudyDate\"")
    private LocalDate lastStudyDate;

    /**
     * Tổng số ngày đã học
     */
    @Column(name = "\"totalStudyDays\"", nullable = false)
    private Integer totalStudyDays = 0;

    @Column(name = "\"updatedAt\"", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // ==================== CONSTRUCTORS ====================

    public StudyStreak() {}

    public StudyStreak(Integer userId) {
        this.userId = userId;
    }

    // ==================== GETTERS & SETTERS ====================

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getCurrentStreak() { return currentStreak; }
    public void setCurrentStreak(Integer currentStreak) { this.currentStreak = currentStreak; }

    public Integer getLongestStreak() { return longestStreak; }
    public void setLongestStreak(Integer longestStreak) { this.longestStreak = longestStreak; }

    public LocalDate getLastStudyDate() { return lastStudyDate; }
    public void setLastStudyDate(LocalDate lastStudyDate) { this.lastStudyDate = lastStudyDate; }

    public Integer getTotalStudyDays() { return totalStudyDays; }
    public void setTotalStudyDays(Integer totalStudyDays) { this.totalStudyDays = totalStudyDays; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    // ==================== BUSINESS LOGIC ====================

    /**
     * Ghi nhận phiên học ngày hôm nay
     * @return true nếu streak được tăng, false nếu đã học hôm nay rồi
     */
    public boolean recordStudyToday() {
        LocalDate today = LocalDate.now();

        if (lastStudyDate == null) {
            // Lần đầu học
            currentStreak = 1;
            longestStreak = 1;
            totalStudyDays = 1;
            lastStudyDate = today;
            updatedAt = LocalDateTime.now();
            return true;
        }

        if (lastStudyDate.equals(today)) {
            // Đã học hôm nay rồi
            return false;
        }

        if (lastStudyDate.equals(today.minusDays(1))) {
            // Học liên tục từ hôm qua
            currentStreak++;
        } else {
            // Mất streak
            currentStreak = 1;
        }

        // Cập nhật longest streak
        if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
        }

        totalStudyDays++;
        lastStudyDate = today;
        updatedAt = LocalDateTime.now();

        return true;
    }

    /**
     * Kiểm tra xem streak có bị mất không (chưa học hôm nay và đã qua 1 ngày từ lần cuối)
     */
    public boolean isStreakAtRisk() {
        if (lastStudyDate == null) return false;
        LocalDate today = LocalDate.now();
        return !lastStudyDate.equals(today) && currentStreak > 0;
    }

    /**
     * Kiểm tra đã học hôm nay chưa
     */
    public boolean hasStudiedToday() {
        if (lastStudyDate == null) return false;
        return lastStudyDate.equals(LocalDate.now());
    }

    /**
     * Tính số ngày còn lại để giữ streak (0 nếu đã học hôm nay hoặc đã mất streak)
     */
    public int getDaysUntilStreakLost() {
        if (lastStudyDate == null || currentStreak == 0) return 0;
        LocalDate today = LocalDate.now();
        if (lastStudyDate.equals(today)) return 1; // Đã học hôm nay, còn 1 ngày
        if (lastStudyDate.equals(today.minusDays(1))) return 0; // Chưa học hôm nay, hết hạn cuối ngày
        return -1; // Đã mất streak
    }
}