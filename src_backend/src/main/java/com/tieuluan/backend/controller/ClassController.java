package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.ClassDTO;
import com.tieuluan.backend.dto.ClassDetailDTO;
import com.tieuluan.backend.dto.ClassMemberDTO;
import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.ClassMemberService;
import com.tieuluan.backend.service.ClassService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * ✅ CLASS CONTROLLER - Quản lý các endpoint liên quan đến Class
 */
@Slf4j
@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ClassController {

    private final ClassService classService;
    private final ClassMemberService classMemberService;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    // ==================== HELPER METHODS ====================

    private Long getUserIdFromAuth(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new RuntimeException("Vui lòng đăng nhập");
        }

        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        return user.getId();
    }

    private boolean isAdmin(Authentication authentication) {
        if (authentication == null) return false;
        return authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }

    // ==================== CLASS CRUD ====================

    /**
     * ✅ GET MY CLASSES - Lấy danh sách lớp mà user là owner
     */
    @GetMapping("/my-classes")
    public ResponseEntity<?> getMyClasses(Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            List<Class> classes = classService.getClassesByTeacher(userId);

            List<ClassDTO> dtos = classes.stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            log.info("✅ Retrieved {} classes for user {}", dtos.size(), userId);
            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            log.error("❌ Error getting my classes: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ GET JOINED CLASSES - Lấy danh sách lớp mà user đã tham gia (APPROVED)
     * Endpoint này đang bị thiếu trong backend!
     */
    @GetMapping("/joined")
    public ResponseEntity<?> getJoinedClasses(Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            // Lấy danh sách lớp đã tham gia với thông tin đầy đủ
            List<Class> joinedClasses = classService.getJoinedClassesByUser(userId);

            // Convert sang DTO
            List<ClassDTO> classes = joinedClasses.stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            log.info("✅ Retrieved {} joined classes for user {}", classes.size(), userId);
            return ResponseEntity.ok(classes);
        } catch (Exception e) {
            log.error("❌ Error getting joined classes: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ GET CLASS DETAIL
     */
    @GetMapping("/{classId}")
    public ResponseEntity<?> getClassDetail(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            boolean isAdmin = isAdmin(authentication);

            Class clazz = classService.getClassById(classId, userId, isAdmin);

            // Convert to DetailDTO with member count
            ClassDetailDTO dto = convertToDetailDTO(clazz, userId);

            return ResponseEntity.ok(dto);
        } catch (Exception e) {
            log.error("❌ Error getting class detail: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ CREATE CLASS
     */
    @PostMapping("/create")
    public ResponseEntity<?> createClass(
            @RequestBody CreateClassRequest request,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            Class created = classService.createClass(
                    request.getName(),
                    request.getDescription(),
                    userId,
                    request.getIsPublic()
            );

            ClassDTO dto = convertToDTO(created);

            log.info("✅ Created class: {}", created.getName());
            return ResponseEntity.ok(dto);
        } catch (Exception e) {
            log.error("❌ Error creating class: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ UPDATE CLASS
     */
    @PutMapping("/{classId}")
    public ResponseEntity<?> updateClass(
            @PathVariable Long classId,
            @RequestBody UpdateClassRequest request,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            boolean isAdmin = isAdmin(authentication);

            Class updated = classService.updateClass(
                    classId,
                    request.getName(),
                    request.getDescription(),
                    userId,
                    isAdmin,
                    request.getIsPublic()
            );

            ClassDTO dto = convertToDTO(updated);

            return ResponseEntity.ok(dto);
        } catch (Exception e) {
            log.error("❌ Error updating class: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ DELETE CLASS
     */
    @DeleteMapping("/{classId}/delete")
    public ResponseEntity<?> deleteClass(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            boolean isAdmin = isAdmin(authentication);

            classService.deleteClass(classId, userId, isAdmin);

            return ResponseEntity.ok(Map.of("message", "Đã xóa lớp học thành công"));
        } catch (Exception e) {
            log.error("❌ Error deleting class: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== JOIN/LEAVE CLASS ====================

    /**
     * ✅ JOIN CLASS BY ID
     */
    @PostMapping("/{classId}/join")
    public ResponseEntity<?> joinClass(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            // Get class info
            Class clazz = classService.getClassById(classId, userId, false);

            // Join via ClassMemberService (handles PENDING/APPROVED logic)
            ClassMemberDTO member = classMemberService.joinByInviteCode(
                    clazz.getInviteCode(),
                    userId
            );

            return ResponseEntity.ok(member);
        } catch (Exception e) {
            log.error("❌ Error joining class: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ JOIN CLASS BY INVITE CODE
     */
    @PostMapping("/join")
    public ResponseEntity<?> joinByInviteCode(
            @RequestBody JoinByCodeRequest request,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            ClassMemberDTO member = classMemberService.joinByInviteCode(
                    request.getInviteCode(),
                    userId
            );

            return ResponseEntity.ok(member);
        } catch (Exception e) {
            log.error("❌ Error joining by invite code: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ LEAVE CLASS
     */
    @DeleteMapping("/{classId}/leave")
    public ResponseEntity<?> leaveClass(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            classService.leaveClass(classId, userId);

            return ResponseEntity.ok(Map.of("message", "Đã rời khỏi lớp học"));
        } catch (Exception e) {
            log.error("❌ Error leaving class: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ CHECK IF USER IS MEMBER
     */
    @GetMapping("/{classId}/is-member")
    public ResponseEntity<?> isMember(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            boolean isOwner = classService.isOwner(classId, userId);
            boolean isMember = classService.isMember(classId, userId);

            Map<String, Object> response = new HashMap<>();
            response.put("isMember", isOwner || isMember);
            response.put("isOwner", isOwner);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of("isMember", false, "isOwner", false));
        }
    }

    // ==================== MEMBERS MANAGEMENT ====================

    /**
     * ✅ GET CLASS MEMBERS
     */
    @GetMapping("/{classId}/members")
    public ResponseEntity<?> getClassMembers(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            List<ClassMemberDTO> members = classMemberService.getClassMembers(classId, userId);

            return ResponseEntity.ok(members);
        } catch (Exception e) {
            log.error("❌ Error getting class members: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ GET PENDING MEMBERS
     */
    @GetMapping("/{classId}/members/pending")
    public ResponseEntity<?> getPendingMembers(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            List<ClassMemberDTO> pendingMembers = classMemberService.getPendingMembers(classId, userId);

            return ResponseEntity.ok(pendingMembers);
        } catch (Exception e) {
            log.error("❌ Error getting pending members: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ APPROVE MEMBER
     */
    @PostMapping("/{classId}/members/{userId}/approve")
    public ResponseEntity<?> approveMember(
            @PathVariable Long classId,
            @PathVariable Long userId,
            Authentication authentication) {
        try {
            Long teacherId = getUserIdFromAuth(authentication);

            ClassMemberDTO approved = classMemberService.approveMember(classId, userId, teacherId);

            return ResponseEntity.ok(approved);
        } catch (Exception e) {
            log.error("❌ Error approving member: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ REJECT MEMBER
     */
    @DeleteMapping("/{classId}/members/{userId}/reject")
    public ResponseEntity<?> rejectMember(
            @PathVariable Long classId,
            @PathVariable Long userId,
            Authentication authentication) {
        try {
            Long teacherId = getUserIdFromAuth(authentication);

            classMemberService.rejectMember(classId, userId, teacherId);

            return ResponseEntity.ok(Map.of("message", "Đã từ chối thành viên"));
        } catch (Exception e) {
            log.error("❌ Error rejecting member: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ REMOVE MEMBER
     */
    @DeleteMapping("/{classId}/members/{userId}")
    public ResponseEntity<?> removeMember(
            @PathVariable Long classId,
            @PathVariable Long userId,
            Authentication authentication) {
        try {
            Long requesterId = getUserIdFromAuth(authentication);

            classMemberService.removeMember(classId, userId, requesterId);

            return ResponseEntity.ok(Map.of("message", "Đã xóa thành viên"));
        } catch (Exception e) {
            log.error("❌ Error removing member: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== SEARCH ====================

    /**
     * ✅ SEARCH PUBLIC CLASSES
     */
    @GetMapping("/search")
    public ResponseEntity<?> searchClasses(@RequestParam String keyword) {
        try {
            List<Class> classes = classService.searchPublicClasses(keyword);

            List<ClassDTO> dtos = classes.stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            log.error("❌ Error searching classes: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ GET PUBLIC CLASSES
     */
    @GetMapping("/public")
    public ResponseEntity<?> getPublicClasses() {
        try {
            List<Class> classes = classService.searchPublicClasses("");

            List<ClassDTO> dtos = classes.stream()
                    .map(this::convertToDTO)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            log.error("❌ Error getting public classes: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ REGENERATE INVITE CODE
     */
    @PostMapping("/{classId}/regenerate-code")
    public ResponseEntity<?> regenerateInviteCode(
            @PathVariable Long classId,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            boolean isAdmin = isAdmin(authentication);

            Class updated = classService.regenerateInviteCode(classId, userId, isAdmin);

            ClassDTO dto = convertToDTO(updated);

            return ResponseEntity.ok(dto);
        } catch (Exception e) {
            log.error("❌ Error regenerating invite code: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== CONVERTERS ====================

    private ClassDTO convertToDTO(Class clazz) {
        ClassDTO dto = new ClassDTO();
        dto.setId(clazz.getId());
        dto.setName(clazz.getName());
        dto.setDescription(clazz.getDescription());
        dto.setOwnerId(clazz.getOwnerId());
        dto.setInviteCode(clazz.getInviteCode());
        dto.setIsPublic(clazz.getIsPublic());
        dto.setCreatedAt(clazz.getCreatedAt());
        dto.setUpdatedAt(clazz.getUpdatedAt());

        // Get owner info
        if (clazz.getOwnerId() != null) {
            userRepository.findById(clazz.getOwnerId()).ifPresent(owner -> {
                dto.setOwnerName(owner.getFullName());
                dto.setOwnerEmail(owner.getEmail());
            });
        }

        // Get member count (approved only) - ClassDTO uses studentCount (Long)
        long memberCount = classMemberService.countApprovedMembers(clazz.getId());
        dto.setStudentCount(memberCount);

        // Get category count
        long categoryCount = classService.getCategoryCountInClass(clazz.getId());
        dto.setCategoryCount(categoryCount);

        return dto;
    }

    private ClassDetailDTO convertToDetailDTO(Class clazz, Long requesterId) {
        ClassDetailDTO dto = new ClassDetailDTO();
        dto.setId(clazz.getId());
        dto.setName(clazz.getName());
        dto.setDescription(clazz.getDescription());
        dto.setOwnerId(clazz.getOwnerId());
        dto.setInviteCode(clazz.getInviteCode());
        dto.setIsPublic(clazz.getIsPublic());
        dto.setCreatedAt(clazz.getCreatedAt());
        dto.setUpdatedAt(clazz.getUpdatedAt());

        // Owner info
        if (clazz.getOwnerId() != null) {
            userRepository.findById(clazz.getOwnerId()).ifPresent(owner -> {
                dto.setOwnerName(owner.getFullName());
                dto.setOwnerEmail(owner.getEmail());
            });
        }

        // Member count (approved only)
        long memberCount = classMemberService.countApprovedMembers(clazz.getId());
        dto.setMemberCount((int) memberCount);

        // Category count
        long categoryCount = classService.getCategoryCountInClass(clazz.getId());
        dto.setCategoryCount((int) categoryCount);

        // Note: ClassDetailDTO doesn't have isOwner/isMember fields
        // These checks should be done in frontend or added to DTO if needed

        return dto;
    }

    // ==================== REQUEST DTOs ====================

    @Data
    public static class CreateClassRequest {
        private String name;
        private String description;
        private Boolean isPublic;
    }

    @Data
    public static class UpdateClassRequest {
        private String name;
        private String description;
        private Boolean isPublic;
    }

    @Data
    public static class JoinByCodeRequest {
        private String inviteCode;
    }
}