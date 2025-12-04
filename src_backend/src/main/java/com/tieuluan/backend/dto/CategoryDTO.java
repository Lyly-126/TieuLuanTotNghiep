package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Category;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.ZonedDateTime;

/**
 * CategoryDTO - ONE-TO-MANY Architecture
 * ✅ Category has classId (nullable)
 * ✅ Simple, no complex relationships
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryDTO {
    private Long id;
    private String name;
    private Boolean isSystem;
    private Long ownerUserId;
    private String ownerEmail;
    private Long classId;            // ✅ ONE-TO-MANY: category thuộc 1 class
    private String visibility;       // PUBLIC, PRIVATE, etc.
    private ZonedDateTime createdAt;
    private Long flashcardCount;

    /**
     * Convert từ Entity sang DTO (basic)
     */
    public static CategoryDTO fromEntity(Category category) {
        CategoryDTO dto = new CategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setIsSystem(category.getIsSystem());
        dto.setOwnerUserId(category.getOwnerUserId());
        dto.setClassId(category.getClassId());  // ✅ ONE-TO-MANY
        dto.setVisibility(category.getVisibility());
        dto.setCreatedAt(category.getCreatedAt());

        // Lấy thông tin owner (nếu có)
        if (category.getOwner() != null) {
            dto.setOwnerEmail(category.getOwner().getEmail());
        }

        // Đếm số flashcards
        if (category.getFlashcards() != null) {
            dto.setFlashcardCount((long) category.getFlashcards().size());
        }

        return dto;
    }

    /**
     * Convert từ Entity sang DTO (simple - không load relationships)
     */
    public static CategoryDTO fromEntitySimple(Category category) {
        CategoryDTO dto = new CategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setIsSystem(category.getIsSystem());
        dto.setOwnerUserId(category.getOwnerUserId());
        dto.setClassId(category.getClassId());  // ✅ ONE-TO-MANY
        dto.setVisibility(category.getVisibility());
        dto.setCreatedAt(category.getCreatedAt());
        return dto;
    }

    // ========== INNER CLASSES ==========

    /**
     * Request: Tạo system category (Admin)
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateSystemRequest {
        private String name;
    }

    /**
     * Request: Tạo user category (any user)
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateUserRequest {
        private String name;
        private String visibility; // PRIVATE (default), PUBLIC (Teacher/Premium only)
    }

    /**
     * Request: Tạo category cho class (Teacher)
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateClassCategoryRequest {
        private String name;
        private Long classId;  // ✅ ONE-TO-MANY
    }

    /**
     * Request: Update category
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private String name;
        private String visibility;
    }

    /**
     * Request: Add category to class (set classId)
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddToClassRequest {
        private Long categoryId;
    }
}