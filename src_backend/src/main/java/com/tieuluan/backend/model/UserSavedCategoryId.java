package com.tieuluan.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Objects;

/**
 * Composite Primary Key for UserSavedCategory
 */
@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserSavedCategoryId implements Serializable {

    @Column(name = "userId")
    private Long userId;

    @Column(name = "categoryId")
    private Long categoryId;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UserSavedCategoryId that = (UserSavedCategoryId) o;
        return Objects.equals(userId, that.userId) &&
                Objects.equals(categoryId, that.categoryId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, categoryId);
    }
}