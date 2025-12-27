package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Category;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * CategoryDTO - Data Transfer Object for Category
 * ✅ Matches DB schema (with description, no timestamps)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryDTO {
    private Long id;
    private String name;
    private String description;
    private Boolean isSystem;
    private Long ownerUserId;
    private Long classId;
    private String className;
    private String visibility;
    private String shareToken;
    private Integer flashcardCount;
    private Boolean isUserCategory;
    private Boolean isClassCategory;
    private Boolean isSaved;

    // ============ FACTORY METHODS ============

    /**
     * Simple conversion (without flashcard count)
     */
    public static CategoryDTO fromEntitySimple(Category category) {
        CategoryDTO dto = new CategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setDescription(category.getDescription());
        dto.setIsSystem(category.getIsSystem());
        dto.setOwnerUserId(category.getOwnerUserId());
        dto.setClassId(category.getClassId());
        dto.setVisibility(category.getVisibility());
        dto.setShareToken(category.getShareToken());

        // Set flags
        dto.setIsUserCategory(category.getOwnerUserId() != null && !category.isSystemCategory());
        dto.setIsClassCategory(category.getClassId() != null);

        return dto;
    }

    /**
     * Full conversion with flashcard count
     */
    public static CategoryDTO fromEntity(Category category) {
        CategoryDTO dto = fromEntitySimple(category);

        // Count flashcards if loaded
        if (category.getFlashcards() != null) {
            dto.setFlashcardCount(category.getFlashcards().size());
        }

        // Get class name if available
        if (category.getClassEntity() != null) {
            dto.setClassName(category.getClassEntity().getName());
        }

        return dto;
    }

    // ============ REQUEST DTOs ============

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateUserRequest {
        private String name;
        private String description;
        private String visibility; // For Teacher/Premium
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateSystemRequest {
        private String name;
        private String description;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private String name;
        private String description;
        private String visibility;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddToClassRequest {
        private Long categoryId;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateClassCategoryRequest {
        private String name;
        private String description;
        private Long classId;
    }
}