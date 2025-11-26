package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Category;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.ZonedDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryDTO {
    private Long id;
    private String name;
    private Boolean isSystem;
    private Long ownerUserId;
    private String ownerEmail;      // Email của owner (nếu có)
    private Long classId;
    private String className;       // Tên lớp (nếu thuộc lớp)
    private ZonedDateTime createdAt;
    private Long flashcardCount;    // Số flashcards trong category

    /**
     * Convert từ Entity sang DTO (basic)
     */
    public static CategoryDTO fromEntity(Category category) {
        CategoryDTO dto = new CategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setIsSystem(category.getIsSystem());
        dto.setOwnerUserId(category.getOwnerUserId());
        dto.setClassId(category.getClassId());
        dto.setCreatedAt(category.getCreatedAt());

        // Lấy thông tin owner (nếu có)
        if (category.getOwner() != null) {
            dto.setOwnerEmail(category.getOwner().getEmail());
        }

        // Lấy tên lớp (nếu có)
        if (category.getClazz() != null) {
            dto.setClassName(category.getClazz().getName());
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
        dto.setClassId(category.getClassId());
        dto.setCreatedAt(category.getCreatedAt());
        return dto;
    }

    // ========== INNER CLASSES ==========

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateSystemRequest {
        private String name;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateUserRequest {
        private String name;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateClassRequest {
        private String name;
        private Long classId;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private String name;
    }
}