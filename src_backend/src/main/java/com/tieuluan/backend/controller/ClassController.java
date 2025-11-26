package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.ClassDTO;
import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.service.ClassService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ClassController {

    private final ClassService classService;

    // ==================== TEACHER ENDPOINTS ====================

    /**
     * TEACHER: Tạo lớp học mới
     */
    @PostMapping("/create")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
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
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> getMyClasses() {
        try {
            Long teacherId = getCurrentUserId();
            List<Class> classes = classService.getClassesByTeacher(teacherId);

            List<ClassDTO> dtos = classes.stream()
                    .map(ClassDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Lấy chi tiết lớp học
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> getClassById(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Class clazz = classService.getClassById(id, userId, isAdmin);
            return ResponseEntity.ok(ClassDTO.fromEntitySimple(clazz));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * TEACHER: Cập nhật lớp học
     */
    @PutMapping("/{id}")
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
     * TEACHER: Xóa lớp học
     */
    @DeleteMapping("/{id}")
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

    /**
     * Lấy số lượng categories trong lớp
     */
    @GetMapping("/{id}/category-count")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> getCategoryCount(@PathVariable Long id) {
        try {
            long count = classService.getCategoryCountInClass(id);
            return ResponseEntity.ok(Map.of("count", count));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Lỗi khi lấy thông tin"));
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

    private Long getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        // TODO: Implement proper user ID retrieval
        // Có thể lưu userId trong JWT claims hoặc query từ UserRepository
        return Long.parseLong(auth.getCredentials().toString());
    }

    private boolean isCurrentUserAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}