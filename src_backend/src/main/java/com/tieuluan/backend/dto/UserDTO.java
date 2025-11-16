package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.ZonedDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {
    private Long id;
    private String email;
    private String fullName;
    private LocalDate dob;
    private String status;
    private String role;
    private ZonedDateTime createdAt;

    // ✅ THÊM 2 FIELDS MỚI
    private Boolean isPremium;
    private Boolean isBlocked;

    // Convert từ Entity sang DTO
    public static UserDTO fromEntity(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setEmail(user.getEmail());
        dto.setFullName(user.getFullName());
        dto.setDob(user.getDob());
        dto.setStatus(user.getStatus().name());
        dto.setRole(user.getRole().name());
        dto.setCreatedAt(user.getCreatedAt());
        dto.setIsPremium(user.getIsPremium()); // ✅
        dto.setIsBlocked(user.getIsBlocked()); // ✅
        return dto;
    }

    // ========== INNER CLASSES ==========

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RegisterRequest {
        private String email;
        private String password;
        private LocalDate dob;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginRequest {
        private String email;
        private String password;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AuthResponse {
        private String token;
        private UserDTO user;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateRequest {
        private LocalDate dob;
        private String status;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateProfileRequest {
        private String fullName;
        private LocalDate dob;
        private String status;
    }
}