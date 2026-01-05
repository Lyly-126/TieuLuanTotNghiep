package com.tieuluan.backend.dto;

import java.time.LocalTime;
import java.util.List;

/**
 * DTO cho Study Reminder Settings
 */
public class StudyReminderDTO {
    private Integer id;
    private LocalTime reminderTime;
    private String daysOfWeek;
    private List<String> enabledDays;  // ["T2", "T3", ...]
    private Boolean isEnabled;
    private String customMessage;

    public StudyReminderDTO() {}

    // Getters & Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public LocalTime getReminderTime() { return reminderTime; }
    public void setReminderTime(LocalTime reminderTime) { this.reminderTime = reminderTime; }

    public String getDaysOfWeek() { return daysOfWeek; }
    public void setDaysOfWeek(String daysOfWeek) { this.daysOfWeek = daysOfWeek; }

    public List<String> getEnabledDays() { return enabledDays; }
    public void setEnabledDays(List<String> enabledDays) { this.enabledDays = enabledDays; }

    public Boolean getIsEnabled() { return isEnabled; }
    public void setIsEnabled(Boolean isEnabled) { this.isEnabled = isEnabled; }

    public String getCustomMessage() { return customMessage; }
    public void setCustomMessage(String customMessage) { this.customMessage = customMessage; }
}