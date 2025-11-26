package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.CategoryDTO;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.CategoryService;
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
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CategoryController {

    private final CategoryService categoryService;
    private final UserRepository userRepository;
    // ==================== PUBLIC/USER ENDPOINTS ====================

    /**
     * Lấy categories available cho user hiện tại
     * (System categories + User's own categories)
     */
    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoryDTO>> getMyCategories() {
        try {
            Long userId = getCurrentUserId();
            List<Category> categories = categoryService.getAvailableCategories(userId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(CategoryDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Lấy tất cả system categories (public)
     */
    @GetMapping("/system")
    public ResponseEntity<List<CategoryDTO>> getSystemCategories() {
        try {
            List<Category> categories = categoryService.getSystemCategories();

            List<CategoryDTO> dtos = categories.stream()
                    .map(CategoryDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * USER: Tạo category cá nhân
     */
    @PostMapping("/create")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> createUserCategory(@RequestBody CategoryDTO.CreateUserRequest request) {
        try {
            Long userId = getCurrentUserId();
            Category category = categoryService.createUserCategory(request.getName(), userId);

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Xóa category (chỉ owner hoặc admin)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> deleteCategory(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            categoryService.deleteCategory(id, userId, isAdmin);
            return ResponseEntity.ok(Map.of("message", "Đã xóa category"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Cập nhật category (chỉ owner hoặc admin)
     */
    @PutMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> updateCategory(
            @PathVariable Long id,
            @RequestBody CategoryDTO.UpdateRequest request) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Category category = categoryService.updateCategory(id, request.getName(), userId, isAdmin);
            return ResponseEntity.ok(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== TEACHER ENDPOINTS ====================

    /**
     * TEACHER: Tạo category cho lớp học
     */
    @PostMapping("/class")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> createClassCategory(@RequestBody CategoryDTO.CreateClassRequest request) {
        try {
            Long teacherId = getCurrentUserId();

            if (request.getClassId() == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Class ID là bắt buộc"));
            }

            Category category = categoryService.createClassCategory(
                    request.getName(),
                    request.getClassId(),
                    teacherId
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Lấy categories của lớp học
     */
    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<CategoryDTO>> getCategoriesForClass(@PathVariable Long classId) {
        try {
            List<Category> categories = categoryService.getCategoriesForClass(classId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(CategoryDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Lấy tất cả categories của teacher (owned + class categories)
     */
    @GetMapping("/teacher")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<CategoryDTO>> getTeacherCategories() {
        try {
            Long teacherId = getCurrentUserId();
            List<Category> categories = categoryService.getTeacherCategories(teacherId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(CategoryDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(List.of((CategoryDTO) Map.of("message", e.getMessage())));
        }
    }

    // ==================== ADMIN ENDPOINTS ====================

    /**
     * ADMIN: Tạo system category
     */
    @PostMapping("/admin/system")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createSystemCategory(@RequestBody CategoryDTO.CreateSystemRequest request) {
        try {
            Category category = categoryService.createSystemCategory(request.getName());
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    private Long getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();

        // Query user từ DB
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User không tồn tại"));

        return user.getId();
    }

    private boolean isCurrentUserAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}