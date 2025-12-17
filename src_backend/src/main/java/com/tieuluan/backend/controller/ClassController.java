package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.ClassDTO;
import com.tieuluan.backend.dto.ClassDetailDTO;
import com.tieuluan.backend.dto.ClassMemberDTO;
import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.model.ClassMember;
import com.tieuluan.backend.model.ClassMemberId;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.ClassMemberRepository;
import com.tieuluan.backend.repository.ClassRepository;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.ClassService;
import com.tieuluan.backend.service.ClassMemberService;
import com.tieuluan.backend.service.UserService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j; // ✅ THÊM IMPORT
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * ✅ CLEAN VERSION - No duplicate methods
 */
@Slf4j // ✅ THÊM ANNOTATION
@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ClassController {

    private final ClassService classService;
    private final ClassMemberService classMemberService;
    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;
    private final UserService userService;
    private final ClassRepository classRepository;
    private final ClassMemberRepository classMemberRepository;

    // ==================== HELPER METHODS - CHỈ MỘT PHẦN DUY NHẤT ====================

    private Long getCurrentUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String email = auth.getName();

            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            return user.getId();
        } catch (Exception e) {
            throw new RuntimeException("Không thể lấy userId từ token: " + e.getMessage());
        }
    }

    private boolean isCurrentUserAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }

    // ==================== ENDPOINTS ====================

    @PostMapping("/create")
    @PreAuthorize("hasAnyRole('TEACHER')")
    public ResponseEntity<?> createClass(@RequestBody ClassDTO.CreateRequest request) {
        try {
            Long teacherId = getCurrentUserId();

            if (request.getName() == null || request.getName().trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Tên lớp không được để trống"));
            }

            Class clazz = classService.createClass(
                    request.getName(),
                    request.getDescription(),
                    teacherId,
                    request.getIsPublic()
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ClassDTO.fromEntitySimple(clazz));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/my-classes")
    @PreAuthorize("hasAnyRole('TEACHER')")
    public ResponseEntity<?> getMyClasses() {
        try {
            Long teacherId = getCurrentUserId();
            List<Class> classes = classService.getClassesByTeacher(teacherId);

            List<ClassDTO> dtos = classes.stream()
                    .map(clazz -> {
                        ClassDTO dto = ClassDTO.fromEntitySimple(clazz);
                        dto.setCategoryCount(classService.getCategoryCountInClass(clazz.getId()));
                        dto.setStudentCount(classMemberService.countMembers(clazz.getId()));
                        return dto;
                    })
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN', 'NORMAL_USER')")
    public ResponseEntity<?> getClassDetail(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Class clazz = classService.getClassById(id, userId, isAdmin);

            ClassDetailDTO detailDTO = new ClassDetailDTO(clazz);

            List<ClassMemberDTO> members = classMemberService.getClassMembers(id, userId);
            detailDTO.setMembers(members);

            detailDTO.setMemberCount((int) classMemberService.countMembers(id));
            detailDTO.setCategoryCount((int) classService.getCategoryCountInClass(id));

            return ResponseEntity.ok(detailDTO);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}/update")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> updateClass(
            @PathVariable Long id,
            @RequestBody ClassDTO.UpdateRequest request) {
        try {
            Long teacherId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Class clazz = classService.updateClass(
                    id,
                    request.getName(),
                    request.getDescription(),
                    teacherId,
                    isAdmin,
                    request.getIsPublic()
            );

            return ResponseEntity.ok(ClassDTO.fromEntitySimple(clazz));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}/delete")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> deleteClass(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            classService.deleteClass(id, userId, isAdmin);
            return ResponseEntity.ok(Map.of("message", "Đã xóa lớp học"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/join")
    @PreAuthorize("hasAnyRole('NORMAL_USER', 'PREMIUM_USER', 'TEACHER', 'ADMIN')")
    public ResponseEntity<?> joinClass(@RequestBody Map<String, String> request) {
        try {
            Long userId = getCurrentUserId();
            String inviteCode = request.get("inviteCode");

            if (inviteCode == null || inviteCode.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Mã lớp không được để trống"));
            }

            ClassMemberDTO member = classMemberService.joinByInviteCode(
                    inviteCode.trim().toUpperCase(),
                    userId
            );

            return ResponseEntity.ok(member);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/{classId}/join")
    @PreAuthorize("hasAnyRole('NORMAL_USER', 'PREMIUM_USER', 'TEACHER', 'ADMIN')")
    public ResponseEntity<?> joinClassById(@PathVariable Long classId) {
        try {
            Long userId = getCurrentUserId();

            Class clazz = classRepository.findById(classId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

            if (clazz.getIsPublic() == null || !clazz.getIsPublic()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Lớp học này không công khai. Vui lòng sử dụng mã mời."));
            }

            boolean isMember = classMemberService.isMember(classId, userId);
            if (isMember) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Bạn đã là thành viên của lớp này"));
            }

            if (clazz.getOwnerId().equals(userId)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Bạn là chủ lớp này"));
            }

            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

            ClassMemberId memberId = new ClassMemberId(classId, userId);
            ClassMember member = new ClassMember();
            member.setId(memberId);
            member.setClassEntity(clazz);
            member.setUser(user);
            member.setRole("STUDENT");
            member.setJoinedAt(java.time.LocalDateTime.now());

            classMemberRepository.save(member);

            ClassMemberDTO memberDTO = new ClassMemberDTO(member);

            return ResponseEntity.ok(Map.of(
                    "message", "Đã tham gia lớp học thành công",
                    "classId", classId,
                    "member", memberDTO
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}/leave")
    @PreAuthorize("hasAnyRole('NORMAL_USER', 'PREMIUM_USER', 'TEACHER')")
    public ResponseEntity<?> leaveClass(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            classService.leaveClass(id, userId);

            return ResponseEntity.ok(Map.of(
                    "message", "Đã rời khỏi lớp học",
                    "classId", id
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{classId}/members/{userId}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> removeMember(
            @PathVariable Long classId,
            @PathVariable Long userId) {
        try {
            Long requesterId = getCurrentUserId();
            classMemberService.removeMember(classId, userId, requesterId);
            return ResponseEntity.ok(Map.of("message", "Đã xóa thành viên"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/joined")
    @PreAuthorize("hasAnyRole('NORMAL_USER', 'PREMIUM_USER', 'TEACHER', 'ADMIN')")
    public ResponseEntity<?> getJoinedClasses() {
        try {
            Long userId = getCurrentUserId();
            List<Long> classIds = classMemberService.getClassIdsByUser(userId);

            List<ClassDTO> classes = classIds.stream()
                    .map(classId -> {
                        try {
                            Class clazz = classService.getClassById(classId, userId, false);
                            ClassDTO dto = ClassDTO.fromEntitySimple(clazz);
                            dto.setCategoryCount(classService.getCategoryCountInClass(classId));
                            dto.setStudentCount(classMemberService.countMembers(classId));
                            return dto;
                        } catch (Exception e) {
                            return null;
                        }
                    })
                    .filter(dto -> dto != null)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(classes);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/search")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ClassDTO>> searchPublicClasses(
            @RequestParam(required = false) String keyword) {
        try {
            List<Class> classes = classService.searchPublicClasses(keyword);

            List<ClassDTO> dtos = classes.stream()
                    .map(ClassDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PostMapping("/{classId}/members/add")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> addMemberByEmail(
            @PathVariable Long classId,
            @RequestBody Map<String, String> request) {
        try {
            Long requesterId = getCurrentUserId();

            String email = request.get("email");
            if (email == null || email.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Email không được để trống"));
            }

            if (!email.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Email không hợp lệ"));
            }

            User currentUser = userRepository.findById(requesterId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy user hiện tại"));

            classService.addMemberByEmail(classId, email.trim(), currentUser.getEmail());

            return ResponseEntity.ok()
                    .body(Map.of("message", "Đã thêm thành viên thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<ClassDTO>> getAllClasses() {
        try {
            List<Class> classes = classService.getAllClasses();

            List<ClassDTO> dtos = classes.stream()
                    .map(ClassDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{id}/membership-status")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> checkMembershipStatus(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();

            boolean isOwner = classService.isOwner(id, userId);
            boolean isMember = classService.isMember(id, userId);

            return ResponseEntity.ok(Map.of(
                    "isOwner", isOwner,
                    "isMember", isMember
            ));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    Map.of("message", e.getMessage())
            );
        }
    }

    // ==================== APPROVAL SYSTEM ====================

    @GetMapping("/{classId}/members/pending")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> getPendingMembers(@PathVariable Long classId) {
        try {
            Long teacherId = getCurrentUserId();
            List<ClassMemberDTO> pendingMembers = classMemberService
                    .getPendingMembers(classId, teacherId);

            return ResponseEntity.ok(pendingMembers);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/{classId}/members/{userId}/approve")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> approveMember(
            @PathVariable Long classId,
            @PathVariable Long userId) {
        try {
            Long teacherId = getCurrentUserId();
            ClassMemberDTO member = classMemberService
                    .approveMember(classId, userId, teacherId);

            return ResponseEntity.ok(Map.of(
                    "message", "Đã duyệt thành viên",
                    "member", member
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/{classId}/members/{userId}/reject")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> rejectMember(
            @PathVariable Long classId,
            @PathVariable Long userId) {
        try {
            Long teacherId = getCurrentUserId();
            classMemberService.rejectMember(classId, userId, teacherId);

            return ResponseEntity.ok(Map.of("message", "Đã từ chối yêu cầu"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping("/{id}/regenerate-invite-code")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> regenerateInviteCode(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Class updatedClass = classService.regenerateInviteCode(id, userId, isAdmin);

            return ResponseEntity.ok(Map.of(
                    "message", "Đã tạo mã mời mới thành công",
                    "inviteCode", updatedClass.getInviteCode(),
                    "classId", updatedClass.getId(),
                    "className", updatedClass.getName()
            ));
        } catch (RuntimeException e) {
            log.error("❌ Error regenerating invite code: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }
}