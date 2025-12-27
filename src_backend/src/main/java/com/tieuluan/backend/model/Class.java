package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.time.ZonedDateTime;
import java.util.List;
import java.util.Random;

/**
 * Class entity - ONE-TO-MANY with Categories
 * ✅ 1 class → many categories
 * ✅ Keep inviteCode for student invitations
 * ✅ FIXED: JsonIgnore for lazy-loaded relations
 */
@Entity
@Table(name = "classes")
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"}) // ✅ THÊM
public class Class {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "ownerId", nullable = false)
    private Long ownerId;

    @Column(name = "inviteCode", unique = true, length = 10)
    private String inviteCode;  // ✅ KEPT for inviting students

    @Column(name = "\"isPublic\"", nullable = false)  // ✅ WITH QUOTES
    private Boolean isPublic = false;

    @Column(name = "createdAt", nullable = false, updatable = false)
    private ZonedDateTime createdAt = ZonedDateTime.now();

    @Column(name = "updatedAt", nullable = false)
    private ZonedDateTime updatedAt = ZonedDateTime.now();

    // ============ Relations - ✅ THÊM @JsonIgnore ============

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ownerId", insertable = false, updatable = false)
    @JsonIgnore // ✅ THÊM: Tránh lỗi serialize User proxy
    private User owner;

    // ✅ ONE-TO-MANY: 1 class → many categories
    @OneToMany(mappedBy = "classEntity", cascade = CascadeType.ALL, orphanRemoval = false)
    @JsonIgnore // ✅ THÊM: Tránh circular reference
    private List<Category> categories;

    @OneToMany(mappedBy = "classEntity", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore // ✅ THÊM: Tránh circular reference
    private List<ClassMember> members;

    // ============ Lifecycle Callbacks ============

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = ZonedDateTime.now();
        }
        if (inviteCode == null || inviteCode.isEmpty()) {
            inviteCode = generateInviteCode();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = ZonedDateTime.now();
    }

    // ============ Helper Methods ============

    public boolean isOwnedBy(Long userId) {
        return ownerId != null && ownerId.equals(userId);
    }

    public int getCategoryCount() {
        return categories != null ? categories.size() : 0;
    }

    public int getMemberCount() {
        return members != null ? members.size() : 0;
    }

    public static String generateInviteCode() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        Random random = new Random();
        StringBuilder code = new StringBuilder();
        int length = 6 + random.nextInt(3);

        for (int i = 0; i < length; i++) {
            code.append(chars.charAt(random.nextInt(chars.length())));
        }

        return code.toString();
    }

    @Override
    public String toString() {
        return "Class{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", ownerId=" + ownerId +
                ", inviteCode='" + inviteCode + '\'' +
                ", categoryCount=" + getCategoryCount() +
                ", memberCount=" + getMemberCount() +
                '}';
    }
}