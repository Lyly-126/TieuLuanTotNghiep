package com.tieuluan.backend.dto;

import com.tieuluan.backend.model.Class;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.ZonedDateTime;
import java.util.List;

/**
 * ✅ COMPLETE FIX:
 * - Removed imageUrl field completely
 * - Added proper member list support
 * - Added statistics (memberCount, categoryCount)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassDetailDTO {
    private Long id;
    private String name;
    private String description;
    private Long ownerId;
    private String ownerName;
    private String ownerEmail;
    private String inviteCode;
    private Boolean isPublic;
    private Integer memberCount;
    private Integer categoryCount;
    private ZonedDateTime createdAt;
    private ZonedDateTime updatedAt;
    private List<ClassMemberDTO> members;

    /**
     * Constructor from Class entity (without members)
     */
    public ClassDetailDTO(Class clazz) {
        this.id = clazz.getId();
        this.name = clazz.getName();
        this.description = clazz.getDescription();
        this.ownerId = clazz.getOwnerId();
        this.inviteCode = clazz.getInviteCode();
        this.isPublic = clazz.getIsPublic();
        this.createdAt = clazz.getCreatedAt();
        this.updatedAt = clazz.getUpdatedAt();

        // Get owner info if available
        if (clazz.getOwner() != null) {
            this.ownerName = clazz.getOwner().getFullName();
            this.ownerEmail = clazz.getOwner().getEmail();
        }
    }

    /**
     * Static factory method with members
     */
    public static ClassDetailDTO fromEntityWithMembers(
            Class clazz,
            List<ClassMemberDTO> members,
            int memberCount,
            int categoryCount) {
        ClassDetailDTO dto = new ClassDetailDTO(clazz);
        dto.setMembers(members);
        dto.setMemberCount(memberCount);
        dto.setCategoryCount(categoryCount);
        return dto;
    }
}