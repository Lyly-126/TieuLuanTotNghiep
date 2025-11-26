package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.ZonedDateTime;

@Entity
@Table(name = "studyPacks")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class StudyPack {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price = BigDecimal.ZERO;

    @Column(name = "durationDays", nullable = false)
    private Integer durationDays = 30;

    // ✅ NEW: targetRole - Gói này upgrade user thành role nào
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TargetRole targetRole = TargetRole.NORMAL_USER;

    @Column(nullable = false, updatable = false)
    private ZonedDateTime createdAt = ZonedDateTime.now();

    @Column(nullable = false)
    private ZonedDateTime updatedAt = ZonedDateTime.now();

    private ZonedDateTime deletedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = ZonedDateTime.now();
        }
        if (targetRole == null) {
            targetRole = TargetRole.NORMAL_USER;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = ZonedDateTime.now();
    }

    // ✅ NEW: TargetRole enum
    public enum TargetRole {
        NORMAL_USER,   // Gói cho user thường → upgrade to PREMIUM_USER
        TEACHER        // Gói cho giáo viên → upgrade to TEACHER
    }
}