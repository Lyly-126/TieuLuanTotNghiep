// File: src/main/java/.../model/ClassMember.java

package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "\"classMembers\"") // ✅ THÊM QUOTES
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassMember {

    @EmbeddedId
    private ClassMemberId id;

    @ManyToOne
    @MapsId("classId")
    @JoinColumn(name = "\"classId\"") // ✅ THÊM QUOTES
    private Class classEntity;

    @ManyToOne
    @MapsId("userId")
    @JoinColumn(name = "\"userId\"") // ✅ THÊM QUOTES
    private User user;

    @Column(name = "role", nullable = false, length = 50)
    private String role = "STUDENT";

    @Column(name = "status", nullable = false, length = 20) // ✅ THÊM CỘT STATUS
    private String status = "APPROVED";

    @Column(name = "\"joinedAt\"", nullable = false) // ✅ THÊM QUOTES
    private LocalDateTime joinedAt = LocalDateTime.now();
}