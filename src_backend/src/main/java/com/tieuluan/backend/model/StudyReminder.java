package com.tieuluan.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Entity lưu cài đặt nhắc nhở học tập của user
 * ✅ FIX: Thêm escaped quotes cho tên bảng và columns để PostgreSQL nhận diện đúng case
 */
@Entity
@Table(name = "\"studyReminders\"")
public class StudyReminder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "\"userId\"", nullable = false)
    private Integer userId;

    /**
     * Thời gian nhắc nhở trong ngày
     */
    @Column(name = "\"reminderTime\"", nullable = false)
    private LocalTime reminderTime = LocalTime.of(20, 0);

    /**
     * Các ngày trong tuần sẽ nhắc (string 7 ký tự: 0=tắt, 1=bật)
     * Index: 0=CN, 1=T2, 2=T3, 3=T4, 4=T5, 5=T6, 6=T7
     * Ví dụ: "0111110" = T2-T6, không CN và T7
     */
    @Column(name = "\"daysOfWeek\"", nullable = false, length = 20)
    private String daysOfWeek = "1111111";

    @Column(name = "\"isEnabled\"", nullable = false)
    private Boolean isEnabled = true;

    /**
     * FCM Token để gửi push notification
     */
    @Column(name = "\"fcmToken\"", columnDefinition = "TEXT")
    private String fcmToken;

    /**
     * Tin nhắn tùy chỉnh
     */
    @Column(name = "\"customMessage\"", length = 255)
    private String customMessage;

    @Column(name = "\"createdAt\"", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "\"updatedAt\"", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // ==================== CONSTRUCTORS ====================

    public StudyReminder() {}

    public StudyReminder(Integer userId) {
        this.userId = userId;
    }

    // ==================== GETTERS & SETTERS ====================

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public LocalTime getReminderTime() { return reminderTime; }
    public void setReminderTime(LocalTime reminderTime) { this.reminderTime = reminderTime; }

    public String getDaysOfWeek() { return daysOfWeek; }
    public void setDaysOfWeek(String daysOfWeek) { this.daysOfWeek = daysOfWeek; }

    public Boolean getIsEnabled() { return isEnabled; }
    public void setIsEnabled(Boolean isEnabled) { this.isEnabled = isEnabled; }

    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }

    public String getCustomMessage() { return customMessage; }
    public void setCustomMessage(String customMessage) { this.customMessage = customMessage; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    // ==================== HELPER METHODS ====================

    /**
     * Kiểm tra có nhắc nhở vào ngày trong tuần hay không
     * @param dayOfWeek 0=CN, 1=T2, ..., 6=T7
     */
    public boolean isReminderEnabledForDay(int dayOfWeek) {
        if (dayOfWeek < 0 || dayOfWeek > 6) return false;
        if (daysOfWeek == null || daysOfWeek.length() < 7) return true;
        return daysOfWeek.charAt(dayOfWeek) == '1';
    }

    /**
     * Bật/tắt nhắc nhở cho một ngày cụ thể
     */
    public void setReminderForDay(int dayOfWeek, boolean enabled) {
        if (dayOfWeek < 0 || dayOfWeek > 6) return;
        if (daysOfWeek == null || daysOfWeek.length() < 7) {
            daysOfWeek = "1111111";
        }
        char[] days = daysOfWeek.toCharArray();
        days[dayOfWeek] = enabled ? '1' : '0';
        daysOfWeek = new String(days);
        updatedAt = LocalDateTime.now();
    }

    /**
     * Lấy danh sách các ngày được bật (tên tiếng Việt)
     */
    public List<String> getEnabledDaysVietnamese() {
        String[] dayNames = {"CN", "T2", "T3", "T4", "T5", "T6", "T7"};
        List<String> enabledDays = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            if (isReminderEnabledForDay(i)) {
                enabledDays.add(dayNames[i]);
            }
        }
        return enabledDays;
    }

    /**
     * Đặt nhắc nhở cho tất cả các ngày
     */
    public void enableAllDays() {
        daysOfWeek = "1111111";
        updatedAt = LocalDateTime.now();
    }

    /**
     * Đặt nhắc nhở chỉ ngày trong tuần (T2-T6)
     */
    public void enableWeekdaysOnly() {
        daysOfWeek = "0111110";
        updatedAt = LocalDateTime.now();
    }

    /**
     * Đặt nhắc nhở chỉ cuối tuần (T7, CN)
     */
    public void enableWeekendsOnly() {
        daysOfWeek = "1000001";
        updatedAt = LocalDateTime.now();
    }

    /**
     * Lấy tin nhắn nhắc nhở (dùng mặc định nếu không có custom)
     */
    public String getDisplayMessage() {
        if (customMessage != null && !customMessage.isBlank()) {
            return customMessage;
        }
        return "🔔 Đến giờ học rồi! Hãy duy trì streak của bạn nhé!";
    }

    /**
     * Tạo reminder time từ giờ và phút
     */
    public void setReminderTime(int hour, int minute) {
        this.reminderTime = LocalTime.of(hour, minute);
        updatedAt = LocalDateTime.now();
    }
}