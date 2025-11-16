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
    private Integer durationDays; // NEW

    public static StudyPackDTO fromEntity(StudyPack e) {
        StudyPackDTO d = new StudyPackDTO();
        d.setId(e.getId());
        d.setName(e.getName());
        d.setDescription(e.getDescription());
        d.setPrice(e.getPrice());
        d.setDurationDays(e.getDurationDays());
        return d;
    }

    @Data
    public static class CreateRequest {
        private String name;
        private String description;
        private BigDecimal price;
        private Integer durationDays; // NEW
    }

    @Data
    public static class UpdateRequest {
        private String name;
        private String description;
        private BigDecimal price;
        private Integer durationDays; // NEW
    }
}