package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.util.List;

/**
 * Category entity - ONE-TO-MANY with Class
 * ✅ Matches DB schema exactly
 * ✅ classId can be NULL (independent categories)
 * ✅ 1 category → 0 or 1 class
 * ✅ Teacher/Premium can create PUBLIC categories
 * ✅ Has description field
 * ✅ FIXED: JsonIgnore for lazy-loaded relations to prevent serialization errors
 */
@Entity
@Table(name = "categories")
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"}) // ✅ THÊM: Ignore Hibernate proxy
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private Boolean isSystem = false;

    @Column(name = "ownerUserId")
    private Long ownerUserId;

    @Column(name = "\"classId\"")  // DOUBLE QUOTES
    private Long classId;

    @Column(length = 30, nullable = false)
    private String visibility = "PRIVATE";

    @Column(length = 32, unique = true)
    private String shareToken;

    // ============ Relations - ✅ THÊM @JsonIgnore ============

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"classId\"", insertable = false, updatable = false)
    @JsonIgnore // ✅ THÊM: Không serialize để tránh lỗi
    private Class classEntity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ownerUserId", insertable = false, updatable = false)
    @JsonIgnore // ✅ THÊM: Không serialize để tránh lỗi
    private User owner;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore // ✅ THÊM: Không serialize để tránh circular reference
    private List<Flashcard> flashcards;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore // ✅ THÊM: Không serialize
    private List<UserSavedCategory> savedByUsers;

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
                ", description='" + description + '\'' +
                ", isSystem=" + isSystem +
                ", classId=" + classId +
                ", visibility='" + visibility + '\'' +
                '}';
    }
}