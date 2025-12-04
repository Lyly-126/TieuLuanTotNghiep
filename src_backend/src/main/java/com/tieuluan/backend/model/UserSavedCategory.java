package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.ZonedDateTime;

/**
 * UserSavedCategory - User favorites
 * ✅ Normal user có thể lưu chủ đề yêu thích
 */
@Entity
@Table(name = "userSavedCategories")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserSavedCategory {

    @EmbeddedId
    private UserSavedCategoryId id;

    @Column(nullable = false)
    private ZonedDateTime savedAt = ZonedDateTime.now();

    // ============ Relations ============

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "userId", insertable = false, updatable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "categoryId", insertable = false, updatable = false)
    private Category category;

    // ============ Constructors ============

    public UserSavedCategory(Long userId, Long categoryId) {
        this.id = new UserSavedCategoryId(userId, categoryId);
        this.savedAt = ZonedDateTime.now();
    }

    // ============ Lifecycle Callbacks ============

    @PrePersist
    protected void onCreate() {
        if (savedAt == null) {
            savedAt = ZonedDateTime.now();
        }
    }
}