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
    private String userRole;
    private String memberRole;

    // ✅ THÊM STATUS
    private String status; // PENDING, APPROVED, REJECTED

    private LocalDateTime joinedAt;

    public ClassMemberDTO(ClassMember member) {
        this.classId = member.getId().getClassId();
        this.userId = member.getId().getUserId();
        this.memberRole = member.getRole();

        // ✅ THÊM STATUS
        this.status = member.getStatus();

        this.joinedAt = member.getJoinedAt();

        if (member.getUser() != null) {
            this.userEmail = member.getUser().getEmail();
            this.userFullName = member.getUser().getFullName();
            this.userRole = member.getUser().getRole().name();
        }
    }
}