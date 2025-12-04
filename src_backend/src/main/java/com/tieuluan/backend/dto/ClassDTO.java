package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Class;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.ZonedDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassDTO {
    private Long id;
    private String name;
    private String description;
    private Long ownerId;
    private String ownerEmail;          // ✅ CHỈ EMAIL
    private ZonedDateTime createdAt;
    private ZonedDateTime updatedAt;
    private Long categoryCount;
    private Long studentCount;

    /**
     * Convert từ Entity sang DTO
     */
    public static ClassDTO fromEntity(Class clazz) {
        ClassDTO dto = new ClassDTO();
        dto.setId(clazz.getId());
        dto.setName(clazz.getName());
        dto.setDescription(clazz.getDescription());
        dto.setOwnerId(clazz.getOwnerId());
        dto.setCreatedAt(clazz.getCreatedAt());
        dto.setUpdatedAt(clazz.getUpdatedAt());

        // ✅ CHỈ LẤY EMAIL
        if (clazz.getOwner() != null) {
            dto.setOwnerEmail(clazz.getOwner().getEmail());
        }

        // ✅ Đếm số categories (ONE-TO-MANY)
        if (clazz.getCategories() != null) {
            dto.setCategoryCount((long) clazz.getCategories().size());
        }

        return dto;
    }

    /**
     * Convert từ Entity sang DTO (simple)
     */
    public static ClassDTO fromEntitySimple(Class clazz) {
        ClassDTO dto = new ClassDTO();
        dto.setId(clazz.getId());
        dto.setName(clazz.getName());
        dto.setDescription(clazz.getDescription());
        dto.setOwnerId(clazz.getOwnerId());
        dto.setCreatedAt(clazz.getCreatedAt());
        dto.setUpdatedAt(clazz.getUpdatedAt());
        return dto;
    }

    // ========== INNER CLASSES ==========

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateRequest {
        private String name;
        private String description;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private String name;
        private String description;
    }
}