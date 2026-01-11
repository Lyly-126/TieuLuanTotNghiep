package com.tieuluan.backend.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalTime;
import java.util.List;

/**
 * DTO cho Category Reminder
 * ✅ Sử dụng Long cho id và categoryId
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryReminderDTO {
    private Long id;
    private Long categoryId;
    private String categoryName;
    private LocalTime reminderTime;
    private Integer hour;
    private Integer minute;
    private String daysOfWeek;
    private List<String> enabledDays;  // ["T2", "T3", "CN"]
    private Boolean isEnabled;
    private String customMessage;

    // Setter tự động tính hour/minute từ reminderTime
    public void setReminderTime(LocalTime time) {
        this.reminderTime = time;
        if (time != null) {
            this.hour = time.getHour();
            this.minute = time.getMinute();
        }
    }
}