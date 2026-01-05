package com.tieuluan.backend.dto;

import java.time.LocalDate;

/**
 * DTO cho Daily Study Log
 */
public class DailyStudyDTO {
    private LocalDate date;
    private Integer cardsStudied;
    private Integer minutesSpent;
    private Integer sessionsCount;
    private Boolean isStudied;  // Có học ngày này không

    public DailyStudyDTO() {}

    public DailyStudyDTO(LocalDate date, boolean isStudied) {
        this.date = date;
        this.isStudied = isStudied;
        this.cardsStudied = 0;
        this.minutesSpent = 0;
        this.sessionsCount = 0;
    }

    // Getters & Setters
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public Integer getCardsStudied() { return cardsStudied; }
    public void setCardsStudied(Integer cardsStudied) { this.cardsStudied = cardsStudied; }

    public Integer getMinutesSpent() { return minutesSpent; }
    public void setMinutesSpent(Integer minutesSpent) { this.minutesSpent = minutesSpent; }

    public Integer getSessionsCount() { return sessionsCount; }
    public void setSessionsCount(Integer sessionsCount) { this.sessionsCount = sessionsCount; }

    public Boolean getIsStudied() { return isStudied; }
    public void setIsStudied(Boolean isStudied) { this.isStudied = isStudied; }
}