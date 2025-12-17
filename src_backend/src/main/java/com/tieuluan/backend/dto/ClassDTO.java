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
    private String ownerName;           // ✅ THÊM owner full name
    private String inviteCode;          // ✅ THÊM dòng này
    private Boolean isPublic;           // ✅ THÊM dòng này
    private ZonedDateTime createdAt;
    private ZonedDateTime updatedAt;
    private Long categoryCount;
    private Long studentCount;

    /**
     * Convert từ Entity sang DTO (full)
     */
    public static ClassDTO fromEntity(Class clazz) {
        ClassDTO dto = new ClassDTO();
        dto.setId(clazz.getId());
        dto.setName(clazz.getName());
        dto.setDescription(clazz.getDescription());
        dto.setOwnerId(clazz.getOwnerId());
        dto.setInviteCode(clazz.getInviteCode());     // ✅ THÊM dòng này
        dto.setIsPublic(clazz.getIsPublic());         // ✅ THÊM dòng này
        dto.setCreatedAt(clazz.getCreatedAt());
        dto.setUpdatedAt(clazz.getUpdatedAt());

        // ✅ LẤY EMAIL VÀ FULL NAME
        if (clazz.getOwner() != null) {
            dto.setOwnerEmail(clazz.getOwner().getEmail());
            dto.setOwnerName(clazz.getOwner().getFullName());
        }

        // ✅ Đếm số categories (ONE-TO-MANY)
        if (clazz.getCategories() != null) {
            dto.setCategoryCount((long) clazz.getCategories().size());
        }

        return dto;
    }

    /**
     * Convert từ Entity sang DTO (simple) - cho search
     * ✅ UPDATED: Thêm ownerName để phân biệt chủ nhân lớp học
     */
    public static ClassDTO fromEntitySimple(Class clazz) {
        ClassDTO dto = new ClassDTO();
        dto.setId(clazz.getId());
        dto.setName(clazz.getName());
        dto.setDescription(clazz.getDescription());
        dto.setOwnerId(clazz.getOwnerId());
        dto.setInviteCode(clazz.getInviteCode());     // ✅ THÊM dòng này
        dto.setIsPublic(clazz.getIsPublic());         // ✅ THÊM dòng này
        dto.setCreatedAt(clazz.getCreatedAt());
        dto.setUpdatedAt(clazz.getUpdatedAt());

        // ✅ THÊM ownerName cho search results
        if (clazz.getOwner() != null) {
            dto.setOwnerName(clazz.getOwner().getFullName());
            dto.setOwnerEmail(clazz.getOwner().getEmail());
        }

        return dto;
    }

    // ========== INNER CLASSES ==========

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateRequest {
        private String name;
        private String description;
        private Boolean isPublic;        // ✅ THÊM dòng này
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private String name;
        private String description;
        private Boolean isPublic;        // ✅ THÊM dòng này
    }
}