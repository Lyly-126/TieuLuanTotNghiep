package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.ZonedDateTime;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserStatus status = UserStatus.UNVERIFIED;

    private LocalDate dob;

    @Column(name = "fullName")
    private String fullName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role = UserRole.USER;

    // ✅ THÊM 2 FIELDS MỚI
    @Column(nullable = false)
    private Boolean isPremium = false;

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
            role = UserRole.USER;
        }
        if (fullName == null || fullName.trim().isEmpty()) {
            fullName = email.split("@")[0];
        }
        // ✅ Set default values
        if (isPremium == null) {
            isPremium = false;
        }
        if (isBlocked == null) {
            isBlocked = false;
        }
    }

    public enum UserStatus {
        UNVERIFIED, VERIFIED, SUSPENDED, BANNED
    }

    public enum UserRole {
        USER, ADMIN
    }
}