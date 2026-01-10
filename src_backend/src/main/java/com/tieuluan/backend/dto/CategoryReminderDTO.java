package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.CategoryReminder;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryReminderDTO {

    private Long id;
    private Long userId;
    private Long categoryId;
    private String categoryName;

    private Integer hour;
    private Integer minute;
    private String reminderTime; // "HH:mm"

    private String daysOfWeek;
    private List<String> enabledDays;

    private Boolean isEnabled;
    private String customMessage;

    // Xung đột
    private Boolean hasConflict;
    private List<ConflictInfo> conflicts;

    public static CategoryReminderDTO fromEntity(CategoryReminder entity, String categoryName) {
        return CategoryReminderDTO.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .categoryId(entity.getCategoryId())
                .categoryName(categoryName)
                .hour(entity.getReminderTime().getHour())
                .minute(entity.getReminderTime().getMinute())
                .reminderTime(entity.getTimeDisplay())
                .daysOfWeek(entity.getDaysOfWeek())
                .enabledDays(entity.getEnabledDaysVietnamese())
                .isEnabled(entity.getIsEnabled())
                .customMessage(entity.getCustomMessage())
                .hasConflict(false)
                .conflicts(new ArrayList<>())
                .build();
    }

    public static CategoryReminderDTO defaultSettings(Long userId, Long categoryId, String categoryName) {
        return CategoryReminderDTO.builder()
                .userId(userId)
                .categoryId(categoryId)
                .categoryName(categoryName)
                .hour(20)
                .minute(0)
                .reminderTime("20:00")
                .daysOfWeek("1111111")
                .enabledDays(List.of("CN", "T2", "T3", "T4", "T5", "T6", "T7"))
                .isEnabled(false)
                .hasConflict(false)
                .conflicts(new ArrayList<>())
                .build();
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConflictInfo {
        private Long categoryId;
        private String categoryName;
        private String reminderTime;
    }
}