package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "\"classMembers\"")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassMember {

    @EmbeddedId  // ✅ Change from @IdClass to @EmbeddedId
    private ClassMemberId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("classId")  // ✅ Maps to ClassMemberId.classId
    @JoinColumn(name = "\"classId\"", insertable = false, updatable = false)
    private Class classEntity;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("userId")  // ✅ Maps to ClassMemberId.userId
    @JoinColumn(name = "\"userId\"", insertable = false, updatable = false)
    private User user;

    @Column(name = "\"role\"", nullable = false, length = 50)
    private String role = "STUDENT";  // ✅ String, not enum

    @Column(name = "\"joinedAt\"", nullable = false)
    private LocalDateTime joinedAt = LocalDateTime.now();  // ✅ LocalDateTime

    @PrePersist
    protected void onCreate() {
        if (joinedAt == null) {
            joinedAt = LocalDateTime.now();
        }
    }
}