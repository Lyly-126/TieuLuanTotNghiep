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
    private String ownerEmail;          // Email của teacher owner
    private String ownerName;           // Tên teacher
    private ZonedDateTime createdAt;
    private ZonedDateTime updatedAt;
    private Long categoryCount;         // Số categories trong lớp
    private Long studentCount;          // Số học sinh (TODO: khi có ClassMember)

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

        // Lấy thông tin owner (nếu có)
        if (clazz.getOwner() != null) {
            dto.setOwnerEmail(clazz.getOwner().getEmail());
            dto.setOwnerName(clazz.getOwner().getFullName());
        }

        // Đếm số categories
        if (clazz.getCategories() != null) {
            dto.setCategoryCount((long) clazz.getCategories().size());
        }

        return dto;
    }

    /**
     * Convert từ Entity sang DTO (simple - không load relationships)
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