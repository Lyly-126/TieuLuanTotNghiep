package com.tieuluan.backend.dto;

import java.time.LocalDate;
import java.util.List;

/**
 * DTO cho Study Streak
 */
public class StudyStreakDTO {
    private Integer currentStreak;
    private Integer longestStreak;
    private LocalDate lastStudyDate;
    private Integer totalStudyDays;
    private Boolean hasStudiedToday;
    private Boolean isStreakAtRisk;
    private List<DailyStudyDTO> weeklyData;  // 7 ngày gần đây

    // Constructors
    public StudyStreakDTO() {}

    // Getters & Setters
    public Integer getCurrentStreak() { return currentStreak; }
    public void setCurrentStreak(Integer currentStreak) { this.currentStreak = currentStreak; }

    public Integer getLongestStreak() { return longestStreak; }
    public void setLongestStreak(Integer longestStreak) { this.longestStreak = longestStreak; }

    public LocalDate getLastStudyDate() { return lastStudyDate; }
    public void setLastStudyDate(LocalDate lastStudyDate) { this.lastStudyDate = lastStudyDate; }

    public Integer getTotalStudyDays() { return totalStudyDays; }
    public void setTotalStudyDays(Integer totalStudyDays) { this.totalStudyDays = totalStudyDays; }

    public Boolean getHasStudiedToday() { return hasStudiedToday; }
    public void setHasStudiedToday(Boolean hasStudiedToday) { this.hasStudiedToday = hasStudiedToday; }

    public Boolean getIsStreakAtRisk() { return isStreakAtRisk; }
    public void setIsStreakAtRisk(Boolean isStreakAtRisk) { this.isStreakAtRisk = isStreakAtRisk; }

    public List<DailyStudyDTO> getWeeklyData() { return weeklyData; }
    public void setWeeklyData(List<DailyStudyDTO> weeklyData) { this.weeklyData = weeklyData; }
}