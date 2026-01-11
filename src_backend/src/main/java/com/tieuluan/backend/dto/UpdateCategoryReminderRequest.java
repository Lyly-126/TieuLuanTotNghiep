package com.tieuluan.backend.dto;

import lombok.Data;

/**
 * Request DTO cho cập nhật Category Reminder
 */
@Data
public class UpdateCategoryReminderRequest {
    private Integer hour;
    private Integer minute;
    private String daysOfWeek;
    private Boolean isEnabled;
    private String customMessage;
    private String fcmToken;
}