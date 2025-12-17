// File: src/main/java/.../model/ClassMemberId.java

package com.tieuluan.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassMemberId implements Serializable {

    @Column(name = "\"classId\"") // ✅ THÊM QUOTES
    private Long classId;

    @Column(name = "\"userId\"") // ✅ THÊM QUOTES
    private Long userId;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ClassMemberId that = (ClassMemberId) o;
        return Objects.equals(classId, that.classId) &&
                Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(classId, userId);
    }
}