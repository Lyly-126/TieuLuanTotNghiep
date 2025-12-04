package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.ZonedDateTime;
import java.util.List;

/**
 * Category entity - ONE-TO-MANY with Class
 * ✅ classId can be NULL (independent categories)
 * ✅ 1 category → 0 or 1 class
 * ✅ Teacher/Premium can create PUBLIC categories
 */
@Entity
@Table(name = "categories")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false)
    private Boolean isSystem = false;

    @Column(name = "ownerUserId")
    private Long ownerUserId;

    @Column(name = "\"classId\"")  // DOUBLE QUOTES
    private Long classId;

    @Column(length = 30, nullable = false)
    private String visibility = "PRIVATE";

    @Column(length = 255)
    private String sharePassword;

    @Column(length = 32, unique = true)
    private String shareToken;

    @Column(nullable = false, updatable = false)
    private ZonedDateTime createdAt = ZonedDateTime.now();

    private ZonedDateTime deletedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"classId\"", insertable = false, updatable = false)
    private Class classEntity;
    // ============ Relations ============

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ownerUserId", insertable = false, updatable = false)
    private User owner;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Flashcard> flashcards;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<UserSavedCategory> savedByUsers;

    // ============ Lifecycle Callbacks ============

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
    }

    // ============ Helper Methods ============

    public boolean isSystemCategory() {
        return isSystem != null && isSystem;
    }

    public boolean isPublic() {
        return "PUBLIC".equals(visibility);
    }

    public boolean isPrivate() {
        return "PRIVATE".equals(visibility);
    }

    public boolean isOwnedBy(Long userId) {
        return ownerUserId != null && ownerUserId.equals(userId);
    }

    public boolean isInClass() {
        return classId != null;
    }

    public boolean isIndependent() {
        return classId == null;
    }

    /**
     * Check if this category can be shared (PUBLIC)
     */
    public boolean canBeShared() {
        return isPublic() && (isSystem || ownerUserId != null);
    }

    /**
     * Get category type for display
     */
    public String getCategoryType() {
        if (isSystem) return "SYSTEM";
        if (isPublic()) return "PUBLIC";
        return "PRIVATE";
    }

    @Override
    public String toString() {
        return "Category{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", isSystem=" + isSystem +
                ", classId=" + classId +
                ", visibility='" + visibility + '\'' +
                '}';
    }
}