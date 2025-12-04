package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.ClassDTO;
import com.tieuluan.backend.dto.ClassDetailDTO;
import com.tieuluan.backend.dto.ClassMemberDTO;
import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.service.ClassService;
import com.tieuluan.backend.service.ClassMemberService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * ✅ COMPLETE FIX:
 * - Added /update and /delete to endpoints
 * - Added getClassDetail endpoint with members
 * - Fixed getCurrentUserId() to use JwtUtil
 */
@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ClassController {

    private final ClassService classService;
    private final ClassMemberService classMemberService;
    private final JwtUtil jwtUtil;

    /**
     * TEACHER: Tạo lớp học mới
     */
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
                    teacherId
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ClassDTO.fromEntitySimple(clazz));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * TEACHER: Lấy tất cả lớp của teacher
     */
    @GetMapping("/my-classes")
    @PreAuthorize("hasAnyRole('TEACHER')")
    public ResponseEntity<?> getMyClasses() {
        try {
            // ✅ LOG ĐỂ DEBUG
            System.out.println("========== GET MY CLASSES CALLED ==========");

            Long teacherId = getCurrentUserId();
            System.out.println("✅ Teacher ID: " + teacherId);

            List<Class> classes = classService.getClassesByTeacher(teacherId);
            System.out.println("✅ Found " + classes.size() + " classes");

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
            System.err.println("❌ Error in getMyClasses: " + e.getMessage());
            e.printStackTrace(); // ✅ IN RA STACK TRACE
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ NEW: Lấy chi tiết lớp học với members
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN', 'NORMAL_USER')")
    public ResponseEntity<?> getClassDetail(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Class clazz = classService.getClassById(id, userId, isAdmin);

            // Tạo ClassDetailDTO
            ClassDetailDTO detailDTO = new ClassDetailDTO(clazz);

            // Thêm thông tin members
            List<ClassMemberDTO> members = classMemberService.getClassMembers(id, userId);
            detailDTO.setMembers(members);

            // Thêm thống kê
            detailDTO.setMemberCount((int) classMemberService.countMembers(id));
            detailDTO.setCategoryCount((int) classService.getCategoryCountInClass(id));

            return ResponseEntity.ok(detailDTO);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ FIXED: TEACHER: Cập nhật lớp học (added /update)
     */
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
                    isAdmin
            );

            return ResponseEntity.ok(ClassDTO.fromEntitySimple(clazz));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ FIXED: TEACHER: Xóa lớp học (added /delete)
     */
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

    /**
     * ✅ NEW: STUDENT: Tham gia lớp qua invite code
     */
    @PostMapping("/join")
    @PreAuthorize("hasAnyRole('NORMAL_USER', 'TEACHER', 'ADMIN')")
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

    /**
     * ✅ NEW: Rời khỏi lớp
     */
    @PostMapping("/{id}/leave")
    @PreAuthorize("hasAnyRole('NORMAL_USER', 'TEACHER')")
    public ResponseEntity<?> leaveClass(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            classMemberService.leaveClass(id, userId);
            return ResponseEntity.ok(Map.of("message", "Đã rời khỏi lớp"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ NEW: TEACHER: Xóa member khỏi lớp
     */
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

    /**
     * ✅ NEW: Lấy danh sách lớp đã tham gia (for students)
     */
    @GetMapping("/joined")
    @PreAuthorize("hasAnyRole('NORMAL_USER', 'TEACHER', 'ADMIN')")
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

    /**
     * TEACHER: Search lớp học
     */
    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<ClassDTO>> searchClasses(@RequestParam(required = false) String keyword) {
        try {
            Long teacherId = getCurrentUserId();
            List<Class> classes = classService.searchClasses(keyword, teacherId);

            List<ClassDTO> dtos = classes.stream()
                    .map(ClassDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // ==================== ADMIN ENDPOINTS ====================

    /**
     * ADMIN: Lấy tất cả lớp học
     */
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

    // ==================== HELPER METHODS ====================

    /**
     * ✅ FIXED: Extract userId from JWT token
     */
    private Long getCurrentUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();

            // ✅ LOG ĐỂ KIỂM TRA
            System.out.println("========== GET CURRENT USER ID ==========");
            System.out.println("Auth: " + auth);
            System.out.println("Principal: " + auth.getPrincipal());
            System.out.println("Credentials: " + auth.getCredentials());

            String token = (String) auth.getCredentials();

            if (token == null || token.isEmpty()) {
                throw new RuntimeException("Token không tồn tại");
            }

            Long userId = jwtUtil.getUserIdFromToken(token);
            System.out.println("✅ Extracted userId: " + userId);

            return userId;
        } catch (Exception e) {
            System.err.println("❌ Error in getCurrentUserId: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Không thể lấy userId từ token: " + e.getMessage());
        }
    }

    private boolean isCurrentUserAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }


    /**
     * Thêm member vào lớp qua email
     */
    @PostMapping("/{classId}/members/add")
    public ResponseEntity<?> addMemberByEmail(
            @PathVariable Integer classId,
            @RequestBody Map<String, String> request,
            @AuthenticationPrincipal UserDetails userDetails) {
        try {
            String email = request.get("email");
            if (email == null || email.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Email không được để trống"));
            }

            classService.addMemberByEmail(Long.valueOf(classId), email, userDetails.getUsername());
            return ResponseEntity.ok()
                    .body(Map.of("message", "Đã thêm thành viên thành công"));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }
}