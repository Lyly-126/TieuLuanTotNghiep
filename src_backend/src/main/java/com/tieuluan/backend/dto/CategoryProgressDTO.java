package com.tieuluan.backend.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/**
 * DTO cho thống kê tiến trình học category
 */
public class CategoryProgressDTO {
    private Integer categoryId;
    private String categoryName;
    private Integer totalCards;           // Tổng số thẻ
    private Integer studiedCards;         // Số thẻ đã học (LEARNING + MASTERED)
    private Integer masteredCards;        // Số thẻ đã thành thạo
    private Integer learningCards;        // Số thẻ đang học
    private Integer notStartedCards;      // Số thẻ chưa học
    private Double progressPercent;       // % tiến độ (studied/total)
    private Double masteryPercent;        // % thành thạo (mastered/total)
    private Integer correctCount;         // Tổng số câu đúng
    private Integer incorrectCount;       // Tổng số câu sai
    private Double accuracyRate;          // Tỷ lệ đúng
    private LocalDateTime lastStudiedAt;  // Lần học cuối

    // Constructors
    public CategoryProgressDTO() {}

    public CategoryProgressDTO(Integer categoryId, String categoryName, Integer totalCards) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.totalCards = totalCards;
        this.studiedCards = 0;
        this.masteredCards = 0;
        this.learningCards = 0;
        this.notStartedCards = totalCards;
        this.progressPercent = 0.0;
        this.masteryPercent = 0.0;
    }

    // Getters & Setters
    public Integer getCategoryId() { return categoryId; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public Integer getTotalCards() { return totalCards; }
    public void setTotalCards(Integer totalCards) { this.totalCards = totalCards; }

    public Integer getStudiedCards() { return studiedCards; }
    public void setStudiedCards(Integer studiedCards) { this.studiedCards = studiedCards; }

    public Integer getMasteredCards() { return masteredCards; }
    public void setMasteredCards(Integer masteredCards) { this.masteredCards = masteredCards; }

    public Integer getLearningCards() { return learningCards; }
    public void setLearningCards(Integer learningCards) { this.learningCards = learningCards; }

    public Integer getNotStartedCards() { return notStartedCards; }
    public void setNotStartedCards(Integer notStartedCards) { this.notStartedCards = notStartedCards; }

    public Double getProgressPercent() { return progressPercent; }
    public void setProgressPercent(Double progressPercent) { this.progressPercent = progressPercent; }

    public Double getMasteryPercent() { return masteryPercent; }
    public void setMasteryPercent(Double masteryPercent) { this.masteryPercent = masteryPercent; }

    public Integer getCorrectCount() { return correctCount; }
    public void setCorrectCount(Integer correctCount) { this.correctCount = correctCount; }

    public Integer getIncorrectCount() { return incorrectCount; }
    public void setIncorrectCount(Integer incorrectCount) { this.incorrectCount = incorrectCount; }

    public Double getAccuracyRate() { return accuracyRate; }
    public void setAccuracyRate(Double accuracyRate) { this.accuracyRate = accuracyRate; }

    public LocalDateTime getLastStudiedAt() { return lastStudiedAt; }
    public void setLastStudiedAt(LocalDateTime lastStudiedAt) { this.lastStudiedAt = lastStudiedAt; }

    // Calculate methods
    public void calculateStats() {
        if (totalCards == null || totalCards == 0) {
            progressPercent = 0.0;
            masteryPercent = 0.0;
            accuracyRate = 0.0;
            studiedCards = 0;
            notStartedCards = 0;
            return;
        }

        studiedCards = (masteredCards != null ? masteredCards : 0) + (learningCards != null ? learningCards : 0);
        notStartedCards = totalCards - studiedCards;
        progressPercent = (double) studiedCards / totalCards * 100;
        masteryPercent = (double) (masteredCards != null ? masteredCards : 0) / totalCards * 100;

        int total = (correctCount != null ? correctCount : 0) + (incorrectCount != null ? incorrectCount : 0);
        accuracyRate = total > 0 ? (double) (correctCount != null ? correctCount : 0) / total * 100 : 0.0;
    }
}