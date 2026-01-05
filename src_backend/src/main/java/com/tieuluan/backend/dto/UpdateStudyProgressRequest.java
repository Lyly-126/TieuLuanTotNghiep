package com.tieuluan.backend.dto;

/**
 * Request DTO cho cập nhật study progress
 */
public class UpdateStudyProgressRequest {
    private Integer flashcardId;
    private Integer categoryId;
    private Boolean isCorrect;

    public Integer getFlashcardId() { return flashcardId; }
    public void setFlashcardId(Integer flashcardId) { this.flashcardId = flashcardId; }

    public Integer getCategoryId() { return categoryId; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }

    public Boolean getIsCorrect() { return isCorrect; }
    public void setIsCorrect(Boolean isCorrect) { this.isCorrect = isCorrect; }
}