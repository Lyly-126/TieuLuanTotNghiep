package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "\"categoryReminders\"", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"\"userId\"", "\"categoryId\""})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryReminder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "\"userId\"", nullable = false)
    private Long userId;

    @Column(name = "\"categoryId\"", nullable = false)
    private Long categoryId;

    @Column(name = "\"reminderTime\"", nullable = false)
    private LocalTime reminderTime = LocalTime.of(20, 0);

    // 7 ký tự: index 0=CN, 1=T2..6=T7. '1'=bật, '0'=tắt
    @Column(name = "\"daysOfWeek\"", nullable = false, length = 7)
    private String daysOfWeek = "1111111";

    @Column(name = "\"isEnabled\"", nullable = false)
    private Boolean isEnabled = true;

    @Column(name = "\"customMessage\"", length = 255)
    private String customMessage;

    // FCM Token để gửi push notification
    @Column(name = "\"fcmToken\"")
    private String fcmToken;

    @Column(name = "\"createdAt\"", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "\"updatedAt\"", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // --- Constructor và Helper Methods giữ nguyên ---
    public CategoryReminder(Long userId, Long categoryId) {
        this.userId = userId;
        this.categoryId = categoryId;
        this.reminderTime = LocalTime.of(20, 0);
        this.daysOfWeek = "1111111";
        this.isEnabled = false;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public boolean isDayEnabled(int dayIndex) {
        if (dayIndex < 0 || dayIndex >= daysOfWeek.length()) return false;
        return daysOfWeek.charAt(dayIndex) == '1';
    }

    public List<String> getEnabledDaysVietnamese() {
        List<String> days = new ArrayList<>();
        String[] dayNames = {"CN", "T2", "T3", "T4", "T5", "T6", "T7"};
        for (int i = 0; i < daysOfWeek.length() && i < 7; i++) {
            if (daysOfWeek.charAt(i) == '1') {
                days.add(dayNames[i]);
            }
        }
        return days;
    }

    public int getEnabledDaysCount() {
        int count = 0;
        for (char c : daysOfWeek.toCharArray()) {
            if (c == '1') count++;
        }
        return count;
    }

    public String getTimeDisplay() {
        return String.format("%02d:%02d", reminderTime.getHour(), reminderTime.getMinute());
    }
}