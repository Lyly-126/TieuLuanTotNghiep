package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.CategoryDTO;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.CategoryService;
import com.tieuluan.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;  // ✅ THÊM IMPORT NÀY
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * ✅ FINAL CLEAN VERSION - With flashcardCount fix
 */
@Slf4j  // ✅ THÊM ANNOTATION NÀY
@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CategoryController {

    private final CategoryService categoryService;
    private final UserRepository userRepository;
    private final UserService userService;
    private final CategoryRepository categoryRepository;

    // ==================== PUBLIC/USER ENDPOINTS ====================

    /**
     * ✅ GET MY CATEGORIES
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
     * ✅ GET MY OWNED CATEGORIES (Chỉ category do user tạo, không có system/public)
     * Dùng cho OCR/PDF khi chọn category để tạo thẻ
     */
    @GetMapping("/my/owned")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoryDTO>> getMyOwnedCategories() {
        try {
            Long userId = getCurrentUserId();

            List<Category> categories = categoryService.getMyOwnedCategoriesOnly(userId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(cat -> convertToDTOWithFlashcardCount(cat, userId))
                    .collect(Collectors.toList());

            log.info("✅ Returning {} owned categories for user {}", dtos.size(), userId);
            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            log.error("❌ Error getting owned categories: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ArrayList<>());
        }
    }

    /**
     * Tạo category cá nhân (PRIVATE)
     */
    @PostMapping("/user")
    @PreAuthorize("hasAnyRole('TEACHER', 'PREMIUM_USER', 'ADMIN')")
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
     * ✅ FIXED: Get PUBLIC categories - Có flashcardCount
     */
    @GetMapping("/public")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoryDTO>> getPublicCategories() {
        try {
            Long userId = getCurrentUserId();
            List<Category> categories = categoryService.getPublicCategories();

            List<CategoryDTO> dtos = categories.stream()
                    .map(cat -> convertToDTOWithFlashcardCount(cat, userId))
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * ✅ HELPER: Convert Category to DTO with flashcardCount
     */
    private CategoryDTO convertToDTOWithFlashcardCount(Category category, Long userId) {
        CategoryDTO dto = new CategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setDescription(category.getDescription());
        dto.setOwnerUserId(category.getOwnerUserId());
        dto.setClassId(category.getClassId());
        dto.setVisibility(category.getVisibility());
        dto.setIsSystem(category.isSystemCategory());
        dto.setShareToken(category.getShareToken());  // ✅ THÊM shareToken

        try {
            long flashcardCount = categoryRepository.countFlashcardsInCategory(category.getId());
            dto.setFlashcardCount((int) flashcardCount);
        } catch (Exception e) {
            dto.setFlashcardCount(0);
        }

        boolean isSaved = userId != null && categoryService.isCategorySaved(userId, category.getId());
        dto.setIsSaved(isSaved);

        dto.setIsUserCategory(category.getOwnerUserId() != null && category.getClassId() == null);
        dto.setIsClassCategory(category.getClassId() != null);

        return dto;
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

            CategoryDTO dto = convertToDTOWithFlashcardCount(category, userId);
            return ResponseEntity.ok(dto);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('TEACHER', 'PREMIUM_USER', 'ADMIN')")
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
                    request.getVisibility(),
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
    @PreAuthorize("hasAnyRole('TEACHER', 'PREMIUM_USER', 'ADMIN')")
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
     * ✅ FIXED: Get categories in a class - Có flashcardCount
     */
    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN', 'NORMAL_USER', 'PREMIUM_USER')")
    public ResponseEntity<?> getCategoriesForClass(@PathVariable Long classId) {
        try {
            Long userId = getCurrentUserId();
            List<Category> categories = categoryService.getCategoriesForClass(classId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(cat -> convertToDTOWithFlashcardCount(cat, userId))
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
     * ✅ FIXED: TEACHER - Có flashcardCount
     */
    @GetMapping("/teacher")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<CategoryDTO>> getTeacherCategories() {
        try {
            Long teacherId = getCurrentUserId();
            List<Category> categories = categoryService.getUserOwnedCategories(teacherId);

            List<CategoryDTO> dtos = categories.stream()
                    .map(cat -> convertToDTOWithFlashcardCount(cat, teacherId))
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
     * ✅ FIXED: ADMIN system categories - Có flashcardCount
     */
    @GetMapping("/admin/system")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<CategoryDTO>> getSystemCategories() {
        try {
            Long userId = getCurrentUserId();
            List<Category> categories = categoryService.getSystemCategories();

            List<CategoryDTO> dtos = categories.stream()
                    .map(cat -> convertToDTOWithFlashcardCount(cat, userId))
                    .collect(Collectors.toList());

            return ResponseEntity.ok(dtos);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // ==================== SEARCH & SAVE ====================

    /**
     * ✅ SEARCH CATEGORIES
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

    // ==================== SHARE BY TOKEN ====================

    /**
     * Lấy category bằng shareToken (public endpoint - không cần auth)
     * URL: GET /api/categories/share/{shareToken}
     */
    @GetMapping("/share/{shareToken}")
    public ResponseEntity<?> getCategoryByShareToken(@PathVariable String shareToken) {
        try {
            log.info("🔗 Getting category by shareToken: {}", shareToken);

            Category category = categoryService.getCategoryByShareToken(shareToken);

            if (category == null) {
                return ResponseEntity.notFound().build();
            }

            // Kiểm tra visibility - chỉ cho phép PUBLIC hoặc SYSTEM
            if (!category.isPublic() && !category.isSystemCategory()) {
                log.warn("⚠️ Attempted to access non-public category via shareToken");
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("message", "Bộ thẻ này không được chia sẻ công khai"));
            }

            CategoryDTO dto = categoryService.convertToDTO(category, null);
            return ResponseEntity.ok(dto);

        } catch (Exception e) {
            log.error("❌ Error getting category by token: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Lưu category từ shareToken vào danh sách của user
     * URL: POST /api/categories/share/{shareToken}/save
     */
    @PostMapping("/share/{shareToken}/save")
    @PreAuthorize("isAuthenticated()")  // ✅ THÊM để đảm bảo user đã login
    public ResponseEntity<?> saveCategoryByShareToken(@PathVariable String shareToken) {
        try {
            Long userId = getCurrentUserId();  // ✅ SỬA: Dùng method có sẵn
            log.info("💾 User {} saving category by shareToken: {}", userId, shareToken);

            CategoryDTO savedCategory = categoryService.saveCategoryByShareToken(shareToken, userId);
            return ResponseEntity.ok(savedCategory);

        } catch (RuntimeException e) {
            log.warn("⚠️ Save category by token failed: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            log.error("❌ Error saving category by token: {}", e.getMessage());
            return ResponseEntity.internalServerError()
                    .body(Map.of("message", "Lỗi server"));
        }
    }

    /**
     * Lấy thông tin public của category (cho preview trước khi save)
     * URL: GET /api/categories/share/{shareToken}/preview
     */
    @GetMapping("/share/{shareToken}/preview")
    public ResponseEntity<?> previewCategoryByShareToken(@PathVariable String shareToken) {
        try {
            log.info("👁️ Preview category by shareToken: {}", shareToken);

            Category category = categoryService.getCategoryByShareToken(shareToken);

            if (category == null) {
                return ResponseEntity.notFound().build();
            }

            if (!category.isPublic() && !category.isSystemCategory()) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("message", "Bộ thẻ này không được chia sẻ công khai"));
            }

            // Trả về thông tin cơ bản (không bao gồm flashcards)
            Map<String, Object> preview = new HashMap<>();
            preview.put("id", category.getId());
            preview.put("name", category.getName());
            preview.put("description", category.getDescription());
            preview.put("visibility", category.getVisibility());
            preview.put("isSystem", category.isSystemCategory());
            preview.put("flashcardCount", categoryService.countFlashcardsInCategory(category.getId()));

            return ResponseEntity.ok(preview);

        } catch (Exception e) {
            log.error("❌ Error previewing category: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
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