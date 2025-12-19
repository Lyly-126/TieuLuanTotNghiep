package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.CategoryDTO;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.CategoryService;
import com.tieuluan.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * ✅ FINAL CLEAN VERSION - No duplicates
 */
@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CategoryController {

    private final CategoryService categoryService;
    private final UserRepository userRepository;
    private final UserService userService;

    // ==================== PUBLIC/USER ENDPOINTS ====================

    /**
     * ✅ GET MY CATEGORIES - CHỈ MỘT METHOD
     */
    @GetMapping("/my")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoryDTO>> getMyCategories() {
        try {
            Long userId = getCurrentUserId();
            List<CategoryDTO> categories = categoryService.getMyCategories(userId);
            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ArrayList<>());
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
                    userId,
                    request.getDescription()
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Tạo category shareable (Teacher/Premium only)
     */
    @PostMapping("/shared")
    @PreAuthorize("hasAnyRole('TEACHER', 'PREMIUM_USER', 'ADMIN')")
    public ResponseEntity<?> createShareableCategory(@RequestBody CategoryDTO.CreateUserRequest request) {
        try {
            Long userId = getCurrentUserId();

            String visibility = request.getVisibility();
            if (visibility == null) {
                visibility = "PUBLIC";
            }

            Category category = categoryService.createShareableCategory(
                    request.getName(),
                    userId,
                    visibility,
                    request.getDescription()
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(CategoryDTO.fromEntitySimple(category));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Get PUBLIC categories
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
                    request.getDescription(),
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
     * Add category to class
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
     * Remove category from class
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
     * Get categories in a class
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
     * TEACHER: Create class category
     */
    @PostMapping("/class")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<?> createClassCategory(@RequestBody CategoryDTO.CreateClassCategoryRequest request) {
        try {
            Long teacherId = getCurrentUserId();

            Category category = categoryService.createClassCategory(
                    request.getName(),
                    request.getDescription(),
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

    @PostMapping("/admin/system")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createSystemCategory(@RequestBody CategoryDTO.CreateSystemRequest request) {
        try {
            Category category = categoryService.createSystemCategory(
                    request.getName(),
                    request.getDescription()
            );

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

    // ==================== SEARCH & SAVE ====================

    /**
     * ✅ SEARCH CATEGORIES - CHỈ MỘT METHOD
     */
    @GetMapping("/search")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoryDTO>> searchCategories(@RequestParam String keyword) {
        try {
            Long userId = getCurrentUserId();
            List<CategoryDTO> categories = categoryService.searchPublicCategoriesDTO(keyword, userId);
            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(new ArrayList<>());
        }
    }

    /**
     * ✅ SAVE CATEGORY
     */
    @PostMapping("/{id}/save")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> saveCategory(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            categoryService.saveCategory(userId, id);

            return ResponseEntity.ok(Map.of(
                    "message", "Đã lưu category thành công",
                    "categoryId", id
            ));
        } catch (Exception e) {
            return ResponseEntity.status(400).body(
                    Map.of("message", e.getMessage())
            );
        }
    }

    /**
     * ✅ UNSAVE CATEGORY
     */
    @DeleteMapping("/{id}/save")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> unsaveCategory(@PathVariable Long id) {
        try {
            Long userId = getCurrentUserId();
            categoryService.unsaveCategory(userId, id);

            return ResponseEntity.ok(Map.of(
                    "message", "Đã bỏ lưu category",
                    "categoryId", id
            ));
        } catch (Exception e) {
            return ResponseEntity.status(400).body(
                    Map.of("message", e.getMessage())
            );
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
    /**
     * ✅ GET SAVED CATEGORIES
     */
    @GetMapping("/saved")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoryDTO>> getSavedCategories() {
        try {
            Long userId = getCurrentUserId();
            List<CategoryDTO> categories = categoryService.getSavedCategories(userId);
            return ResponseEntity.ok(categories);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ArrayList<>());
        }
    }
}