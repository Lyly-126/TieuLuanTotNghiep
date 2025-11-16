package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Policy;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.ZonedDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PolicyDTO {

    private Long id;
    private String title;
    private String body;
    private String status;
    private ZonedDateTime createdAt;
    private ZonedDateTime updatedAt;

    // Request DTOs
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateRequest {
        private String title;
        private String body;
        private String status; // ACTIVE, INACTIVE, DRAFT
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private String title;
        private String body;
        private String status;
    }

    // Mapper method
    public static PolicyDTO fromEntity(Policy policy) {
        PolicyDTO dto = new PolicyDTO();
        dto.setId(policy.getId());
        dto.setTitle(policy.getTitle());
        dto.setBody(policy.getBody());
        dto.setStatus(policy.getStatus().name());
        dto.setCreatedAt(policy.getCreatedAt());
        dto.setUpdatedAt(policy.getUpdatedAt());
        return dto;
    }
}