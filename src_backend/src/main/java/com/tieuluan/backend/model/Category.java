package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.ZonedDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "categories")
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    // ✅ NEW: Ownership fields
    @Column(nullable = false)
    private Boolean isSystem = false;      // System category (public)

    @Column(name = "ownerUserId")
    private Long ownerUserId;              // User category owner

    @Column(name = "classId")
    private Long classId;                  // Class category

    @Column(nullable = false)
    private ZonedDateTime createdAt = ZonedDateTime.now();

    private ZonedDateTime deletedAt;       // Soft delete

    // ✅ Relations
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ownerUserId", insertable = false, updatable = false)
    private User owner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "classId", insertable = false, updatable = false)
    private Class clazz;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Flashcard> flashcards;

    // ✅ Constructors
    public Category(String name) {
        this.name = name;
        this.isSystem = false;
        this.createdAt = ZonedDateTime.now();
    }

    public Category(String name, Boolean isSystem) {
        this.name = name;
        this.isSystem = isSystem;
        this.createdAt = ZonedDateTime.now();
    }

    public Category(String name, Long ownerUserId) {
        this.name = name;
        this.isSystem = false;
        this.ownerUserId = ownerUserId;
        this.createdAt = ZonedDateTime.now();
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
        if (isSystem == null) {
            isSystem = false;
        }
    }

    // ✅ Helper methods
    public Boolean getIsSystem() {
        return isSystem != null ? isSystem : false;
    }

    public boolean isOwnedBy(Long userId) {
        return ownerUserId != null && ownerUserId.equals(userId);
    }

    public boolean isSystemCategory() {
        return Boolean.TRUE.equals(isSystem);
    }

    public boolean isUserCategory() {
        return !isSystemCategory() && classId == null;
    }

    public boolean isClassCategory() {
        return classId != null;
    }

    public String getCategoryType() {
        if (isSystemCategory()) return "SYSTEM";
        if (isClassCategory()) return "CLASS";
        return "USER";
    }

    @Override
    public String toString() {
        return "Category{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", type=" + getCategoryType() +
                ", ownerUserId=" + ownerUserId +
                ", classId=" + classId +
                '}';
    }
}