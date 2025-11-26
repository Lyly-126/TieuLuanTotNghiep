package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.StudyPack;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.ZonedDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudyPackDTO {
    private Long id;
    private String name;
    private String description;
    private BigDecimal price;
    private Integer durationDays;
    private String targetRole;  // ✅ THÊM MỚI: "NORMAL_USER" hoặc "TEACHER"
    private ZonedDateTime createdAt;
    private ZonedDateTime updatedAt;

    // Convert từ Entity sang DTO
    public static StudyPackDTO fromEntity(StudyPack pack) {
        StudyPackDTO dto = new StudyPackDTO();
        dto.setId(pack.getId());
        dto.setName(pack.getName());
        dto.setDescription(pack.getDescription());
        dto.setPrice(pack.getPrice());
        dto.setDurationDays(pack.getDurationDays());
        dto.setTargetRole(pack.getTargetRole().name());  // ✅ Map enum sang string
        dto.setCreatedAt(pack.getCreatedAt());
        dto.setUpdatedAt(pack.getUpdatedAt());
        return dto;
    }

    // ========== INNER CLASSES ==========

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateRequest {
        private String name;
        private String description;
        private BigDecimal price;
        private Integer durationDays;
        private String targetRole;  // ✅ THÊM MỚI: "NORMAL_USER" hoặc "TEACHER"
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private String name;
        private String description;
        private BigDecimal price;
        private Integer durationDays;
        private String targetRole;  // ✅ THÊM MỚI
    }
}