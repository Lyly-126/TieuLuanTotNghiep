package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.ClassMember;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassMemberDTO {
    private Long classId;
    private Long userId;
    private String userEmail;
    private String userFullName;
    private String userRole;      // User's system role (TEACHER, NORMAL_USER, etc.)
    private String memberRole;    // ✅ FIXED: String instead of enum
    private LocalDateTime joinedAt; // ✅ FIXED: LocalDateTime instead of ZonedDateTime

    // ✅ FIXED: Constructor từ ClassMember entity
    public ClassMemberDTO(ClassMember member) {
        // Access embedded ID fields
        this.classId = member.getId().getClassId();      // ✅ Through getId()
        this.userId = member.getId().getUserId();        // ✅ Through getId()

        this.memberRole = member.getRole();              // ✅ Already String
        this.joinedAt = member.getJoinedAt();            // ✅ Already LocalDateTime

        // Safe null check for User
        if (member.getUser() != null) {
            this.userEmail = member.getUser().getEmail();
            this.userFullName = member.getUser().getFullName();
            this.userRole = member.getUser().getRole().name();
        }
    }
}