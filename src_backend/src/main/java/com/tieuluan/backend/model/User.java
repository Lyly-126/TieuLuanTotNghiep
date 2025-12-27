package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.time.LocalDate;
import java.time.ZonedDateTime;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"}) // ✅ THÊM: Ignore Hibernate proxy
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    @JsonIgnore // ✅ THÊM: Không bao giờ serialize password
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserStatus status = UserStatus.UNVERIFIED;

    private LocalDate dob;

    @Column(name = "fullName")
    private String fullName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role = UserRole.NORMAL_USER;

    @Column(nullable = false)
    private Boolean isBlocked = false;

    @Column(nullable = false, updatable = false)
    private ZonedDateTime createdAt = ZonedDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
        if (status == null) {
            status = UserStatus.UNVERIFIED;
        }
        if (role == null) {
            role = UserRole.NORMAL_USER;
        }
        if (fullName == null || fullName.trim().isEmpty()) {
            fullName = email.split("@")[0];
        }
        if (isBlocked == null) {
            isBlocked = false;
        }
    }

    public enum UserStatus {
        UNVERIFIED, VERIFIED, SUSPENDED, BANNED
    }

    public enum UserRole {
        NORMAL_USER,    // User thường (free)
        PREMIUM_USER,   // User đã mua gói premium
        TEACHER,        // Giáo viên (có thể tạo lớp)
        ADMIN           // Quản trị viên
    }
}