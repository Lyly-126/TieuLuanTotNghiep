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

/**
 * CategoryController - ONE-TO-MANY Architecture
 * ✅ Category has classId (nullable)
 * ✅ 1 category → 0 or 1 class
 * ❌ NO ClassSet!
 */
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
     * Tạo category cá nhân (PRIVATE)
     */
    @PostMapping("/user")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> createUserCategory(@RequestBody CategoryDTO.CreateUserRequest request) {
        try {
            Long userId = getCurrentUserId();

            Category category = categoryService.createUserCategory(
                    request.getName(),
                    userId
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ Tạo category shareable (Teacher/Premium only)
     */
    @PostMapping("/shared")
    @PreAuthorize("hasAnyRole('TEACHER', 'PREMIUM_USER', 'ADMIN')")
    public ResponseEntity<?> createShareableCategory(@RequestBody CategoryDTO.CreateUserRequest request) {
        try {
            Long userId = getCurrentUserId();

            // Validate visibility
            String visibility = request.getVisibility();
            if (visibility == null) {
                visibility = "PUBLIC"; // Default for Teacher/Premium
            }

            Category category = categoryService.createShareableCategory(
                    request.getName(),
                    userId,
                    visibility
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ Get PUBLIC categories (shareable)
     */
    @GetMapping("/public")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoryDTO>> getPublicCategories() {
        try {
            List<Category> categories = categoryService.getPublicCategories();

            List<CategoryDTO> dtos = categories.stream()
                    .map(CategoryDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Lấy category by ID
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getCategoryById(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Category category = categoryService.getCategoryById(id, userId, isAdmin);
            return ResponseEntity.ok(CategoryDTO.fromEntity(category));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Cập nhật category
     */
    @PutMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> updateCategory(
            @PathVariable Long id,
            @RequestBody CategoryDTO.UpdateRequest request) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            Category updated = categoryService.updateCategory(
                    id,
                    request.getName(),
                    userId,
                    isAdmin
            );

            return ResponseEntity.ok(CategoryDTO.fromEntitySimple(updated));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Xóa category
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> deleteCategory(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            categoryService.deleteCategory(id, userId, isAdmin);
            return ResponseEntity.ok(Map.of("message", "Đã xóa category thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== TEACHER ENDPOINTS ====================

    /**
     * ✅ ONE-TO-MANY: Add category to class (set classId)
     * Replaces old addCategoryToClass with ClassSet
     */
    @PostMapping("/class/{classId}/add")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> addCategoryToClass(
            @PathVariable Long classId,
            @RequestBody CategoryDTO.AddToClassRequest request) {
        try {
            Long userId = getCurrentUserId();

            if (request.getCategoryId() == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Category ID là bắt buộc"));
            }

            // ✅ Returns Category (not ClassSet)
            Category category = categoryService.addCategoryToClass(
                    request.getCategoryId(),
                    classId,
                    userId
            );

            return ResponseEntity.ok(Map.of(
                    "message", "Đã thêm category vào lớp",
                    "categoryId", category.getId(),
                    "classId", category.getClassId()
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ Remove category from class (set classId = null)
     */
    @DeleteMapping("/class/{classId}/remove/{categoryId}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> removeCategoryFromClass(
            @PathVariable Long classId,
            @PathVariable Long categoryId) {
        try {
            Long userId = getCurrentUserId();
            boolean isAdmin = isCurrentUserAdmin();

            categoryService.removeCategoryFromClass(categoryId, classId, userId, isAdmin);

            return ResponseEntity.ok(Map.of("message", "Đã xóa category khỏi lớp"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * ✅ Get categories in a class (ONE-TO-MANY)
     */
    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN', 'NORMAL_USER')")
    public ResponseEntity<?> getCategoriesForClass(@PathVariable Long classId) {
        try {
            List<Category> categories = categoryService.getCategoriesForClass(classId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(CategoryDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * TEACHER: Lấy danh sách categories của teacher
     */
    @GetMapping("/teacher")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<CategoryDTO>> getTeacherCategories() {
        try {
            Long teacherId = getCurrentUserId();
            List<Category> categories = categoryService.getUserOwnedCategories(teacherId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(CategoryDTO::fromEntitySimple)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
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

    /**
     * ADMIN: Lấy tất cả system categories
     */
    @GetMapping("/admin/system")
    @PreAuthorize("hasRole('ADMIN')")
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

    // ==================== HELPER METHODS ====================

    private Long getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();

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