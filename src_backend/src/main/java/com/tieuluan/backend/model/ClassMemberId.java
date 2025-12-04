package com.tieuluan.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Objects;

@Embeddable  // ✅ Add @Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassMemberId implements Serializable {

    @Column(name = "\"classId\"")  // ✅ Add @Column with quotes
    private Long classId;

    @Column(name = "\"userId\"")  // ✅ Add @Column with quotes
    private Long userId;

    // ✅ Override equals() and hashCode() for composite key
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