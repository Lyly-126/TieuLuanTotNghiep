package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.CategoryDTO;
import com.tieuluan.backend.model.*;
import com.tieuluan.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * ✅ FIXED: Thêm shareToken cho TẤT CẢ loại category (kể cả user category độc lập)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final ClassRepository classRepository;
    private final UserRepository userRepository;
    private final UserSavedCategoryRepository userSavedCategoryRepository;
    private final ClassMemberRepository classMemberRepository;

    private void validateCategoryName(String name) {
        if (name == null || name.trim().isEmpty()) {
            throw new RuntimeException("Tên category không được để trống");
        }
        if (name.length() > 100) {
            throw new RuntimeException("Tên category không được quá 100 ký tự");
        }
    }

    private String generateShareToken() {
        return "tok_" + UUID.randomUUID().toString().replace("-", "").substring(0, 24);
    }

    @Transactional
    public Category createSystemCategory(String name, String description) {
        validateCategoryName(name);

        if (categoryRepository.existsByName(name)) {
            throw new RuntimeException("Tên category đã tồn tại");
        }

        Category category = new Category();
        category.setName(name);
        category.setDescription(description);
        category.setIsSystem(true);
        category.setOwnerUserId(null);
        category.setClassId(null);
        category.setVisibility("PUBLIC");
        category.setShareToken(generateShareToken());  // ✅ Có shareToken

        log.info("✅ Created system category: {}", name);
        return categoryRepository.save(category);
    }

    /**
     * ✅ FIXED: Thêm shareToken cho user category độc lập
     * Trước đây hàm này KHÔNG có setShareToken()
     */
    @Transactional
    public Category createUserCategory(String name, Long userId, String description) {
        validateCategoryName(name);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        List<Category> userCategories = categoryRepository.findByOwnerUserId(userId);
        boolean nameExists = userCategories.stream()
                .anyMatch(c -> c.getName().equalsIgnoreCase(name));

        if (nameExists) {
            throw new RuntimeException("Bạn đã có category với tên này");
        }

        Category category = new Category();
        category.setName(name);
        category.setDescription(description);
        category.setIsSystem(false);
        category.setOwnerUserId(userId);
        category.setClassId(null);
        category.setVisibility("PRIVATE");
        category.setShareToken(generateShareToken());  // ✅ THÊM DÒNG NÀY - ĐÂY LÀ FIX CHÍNH

        log.info("✅ User {} created personal category: {} with shareToken", user.getEmail(), name);
        return categoryRepository.save(category);
    }

    @Transactional
    public Category createShareableCategory(String name, Long userId, String visibility, String description) {
        validateCategoryName(name);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User không tồn tại"));

        String role = String.valueOf(user.getRole());
        if (!role.equals("TEACHER") && !role.equals("PREMIUM_USER") && !role.equals("ADMIN")) {
            throw new RuntimeException("Chỉ Teacher/Premium User mới được tạo category PUBLIC");
        }

        Category category = new Category();
        category.setName(name);
        category.setDescription(description);
        category.setIsSystem(false);
        category.setOwnerUserId(userId);
        category.setClassId(null);
        category.setVisibility(visibility);
        category.setShareToken(generateShareToken());  // ✅ Có shareToken

        log.info("✅ User {} created shareable category: {} (visibility={})",
                user.getEmail(), name, visibility);
        return categoryRepository.save(category);
    }

    @Transactional
    public Category createClassCategory(String name, String description, Long classId, Long teacherId) {
        validateCategoryName(name);

        com.tieuluan.backend.model.Class classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Lớp học không tồn tại"));

        if (!classEntity.getOwnerId().equals(teacherId)) {
            throw new RuntimeException("Bạn không phải chủ lớp học này");
        }

        Category category = new Category();
        category.setName(name);
        category.setDescription(description);
        category.setIsSystem(false);
        category.setOwnerUserId(teacherId);
        category.setClassId(classId);
        category.setVisibility("PUBLIC");
        category.setShareToken(generateShareToken());  // ✅ Có shareToken

        log.info("✅ Created class category: classId={}, name={}", classId, name);
        return categoryRepository.save(category);
    }

    @Transactional
    public Category updateCategory(Long categoryId, String name, String description,
                                   String visibility, Long userId, boolean isAdmin) {
        validateCategoryName(name);

        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

        if (!isAdmin && !category.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không phải chủ nhân của học phần này");
        }

        if (category.isSystemCategory() && !isAdmin) {
            throw new RuntimeException("Không thể sửa học phần hệ thống");
        }

        category.setName(name);
        category.setDescription(description);

        if (visibility != null && !visibility.isEmpty()) {
            if (!visibility.equals("PUBLIC") && !visibility.equals("PRIVATE")) {
                throw new RuntimeException("Visibility phải là PUBLIC hoặc PRIVATE");
            }
            category.setVisibility(visibility);
        }

        // ✅ THÊM: Tự động tạo shareToken nếu chưa có
        if (category.getShareToken() == null || category.getShareToken().isEmpty()) {
            category.setShareToken(generateShareToken());
            log.info("✅ Generated missing shareToken for category: {}", categoryId);
        }

        log.info("✅ Updated category: {} by user {}", name, userId);
        return categoryRepository.save(category);
    }

    @Transactional
    public void deleteCategory(Long categoryId, Long userId, boolean isAdmin) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy category"));

        if (category.isSystemCategory() && !isAdmin) {
            throw new RuntimeException("Chỉ admin mới có thể xóa học phần hệ thống");
        }

        if (!isAdmin && !category.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không phải chủ nhân của học phần này");
        }

        String categoryName = category.getName();

        long flashcardCount = categoryRepository.countFlashcardsInCategory(categoryId);

        categoryRepository.delete(category);

        log.info("✅ Deleted category '{}' with {} flashcards by user {}",
                categoryName, flashcardCount, userId);
    }

    public List<Category> getSystemCategories() {
        return categoryRepository.findByIsSystemTrue();
    }

    public List<Category> getUserOwnedCategories(Long userId) {
        return categoryRepository.findByOwnerUserId(userId);
    }

    public List<Category> getPublicCategories() {
        return categoryRepository.findPublicCategories();
    }

    public List<Category> getCategoriesForClass(Long classId) {
        return categoryRepository.findByClassId(classId);
    }

    /**
     * ✅ NEW: Lấy categories do user sở hữu (KHÔNG có system)
     */
    public List<Category> getMyOwnedCategoriesOnly(Long userId) {
        return categoryRepository.findByOwnerUserId(userId).stream()
                .filter(cat -> !cat.isSystemCategory())
                .collect(Collectors.toList());
    }

    public Category getCategoryById(Long categoryId, Long userId, boolean isAdmin) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

        if (isAdmin) return category;
        if (category.isSystemCategory()) return category;
        if (category.isPublic()) return category;
        if (category.isOwnedBy(userId)) return category;

        if (category.getClassId() != null) {
            ClassMemberId memberId = new ClassMemberId(category.getClassId(), userId);
            if (classMemberRepository.existsById(memberId)) {
                return category;
            }
        }

        throw new RuntimeException("Bạn không có quyền xem category này");
    }

    public List<Category> searchPublicCategories(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return categoryRepository.findPublicCategories();
        }

        String lowerKeyword = keyword.toLowerCase().trim();
        List<Category> publicCategories = categoryRepository.findPublicCategories();

        return publicCategories.stream()
                .filter(c -> {
                    boolean matchName = c.getName().toLowerCase().contains(lowerKeyword);
                    boolean matchDesc = c.getDescription() != null &&
                            c.getDescription().toLowerCase().contains(lowerKeyword);
                    return matchName || matchDesc;
                })
                .collect(Collectors.toList());
    }

    public boolean canUserAccessCategory(Long categoryId, Long userId) {
        return categoryRepository.isAccessibleByUser(categoryId, userId);
    }

    @Transactional
    public void saveCategory(Long userId, Long categoryId) {
        UserSavedCategoryId id = new UserSavedCategoryId(userId, categoryId);
        if (userSavedCategoryRepository.existsById(id)) {
            throw new RuntimeException("Category đã được lưu");
        }

        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

        if (!category.isSystemCategory() && !category.isPublic()) {
            throw new RuntimeException("Chỉ có thể lưu category PUBLIC");
        }

        UserSavedCategory saved = new UserSavedCategory(userId, categoryId);
        userSavedCategoryRepository.save(saved);

        log.info("✅ User {} saved category {}", userId, categoryId);
    }

    @Transactional
    public void unsaveCategory(Long userId, Long categoryId) {
        UserSavedCategoryId id = new UserSavedCategoryId(userId, categoryId);

        if (!userSavedCategoryRepository.existsById(id)) {
            throw new RuntimeException("Category chưa được lưu");
        }

        userSavedCategoryRepository.deleteById(id);
        log.info("✅ User {} unsaved category {}", userId, categoryId);
    }

    public List<CategoryDTO> getSavedCategories(Long userId) {
        List<UserSavedCategory> savedList = userSavedCategoryRepository.findByUserId(userId);

        return savedList.stream()
                .map(saved -> {
                    Category category = categoryRepository.findById(saved.getId().getCategoryId())
                            .orElse(null);
                    if (category != null) {
                        return convertToDTOWithSavedStatus(category, userId, true);
                    }
                    return null;
                })
                .filter(dto -> dto != null)
                .collect(Collectors.toList());
    }

    public boolean isCategorySaved(Long userId, Long categoryId) {
        UserSavedCategoryId id = new UserSavedCategoryId(userId, categoryId);
        return userSavedCategoryRepository.existsById(id);
    }

    public List<CategoryDTO> searchPublicCategoriesDTO(String keyword, Long currentUserId) {
        List<Category> categories = categoryRepository.searchPublicCategories(keyword);

        return categories.stream()
                .map(category -> convertToDTOWithSavedStatus(category, currentUserId, false))
                .collect(Collectors.toList());
    }

    private CategoryDTO convertToDTOWithSavedStatus(Category category, Long userId, boolean forceSaved) {
        CategoryDTO dto = new CategoryDTO();
        dto.setId(category.getId());
        dto.setName(category.getName());
        dto.setDescription(category.getDescription());
        dto.setOwnerUserId(category.getOwnerUserId());
        dto.setClassId(category.getClassId());
        dto.setVisibility(category.getVisibility());
        dto.setIsSystem(category.isSystemCategory());
        dto.setShareToken(category.getShareToken());  // ✅ QUAN TRỌNG: Đảm bảo trả về shareToken

        try {
            long flashcardCount = categoryRepository.countFlashcardsInCategory(category.getId());
            dto.setFlashcardCount((int) flashcardCount);
        } catch (Exception e) {
            log.warn("Error counting flashcards for category {}: {}", category.getId(), e.getMessage());
            dto.setFlashcardCount(0);
        }

        boolean isSaved = forceSaved || (userId != null && isCategorySaved(userId, category.getId()));
        dto.setIsSaved(isSaved);

        dto.setIsUserCategory(category.getOwnerUserId() != null && category.getClassId() == null);
        dto.setIsClassCategory(category.getClassId() != null);

        return dto;
    }

    public List<CategoryDTO> getMyCategories(Long userId) {
        List<CategoryDTO> result = new ArrayList<>();

        try {
            List<Category> systemCategories = categoryRepository.findByIsSystemTrue();
            systemCategories.forEach(cat -> result.add(convertToDTOWithSavedStatus(cat, userId, false)));

            List<Category> ownCategories = categoryRepository.findByOwnerUserId(userId);
            ownCategories.forEach(cat -> result.add(convertToDTOWithSavedStatus(cat, userId, false)));

            result.addAll(getSavedCategories(userId));

            List<ClassMember> memberships = classMemberRepository.findByIdUserId(userId);
            for (ClassMember membership : memberships) {
                List<Category> classCategories = categoryRepository.findByClassId(membership.getId().getClassId());
                classCategories.forEach(cat -> result.add(convertToDTOWithSavedStatus(cat, userId, false)));
            }

            return result.stream()
                    .collect(Collectors.toMap(
                            CategoryDTO::getId,
                            dto -> dto,
                            (existing, replacement) -> existing
                    ))
                    .values()
                    .stream()
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("❌ Error in getMyCategories for user {}: {}", userId, e.getMessage(), e);
            throw new RuntimeException("Không thể tải danh sách chủ đề: " + e.getMessage());
        }
    }

    public List<CategoryDTO> getMyCategoriesForFlashcardCreation(Long userId) {
        log.info("📋 Getting categories for flashcard creation for user {}", userId);

        List<CategoryDTO> result = new ArrayList<>();

        try {
            List<Category> ownCategories = categoryRepository.findByOwnerUserId(userId);

            ownCategories.stream()
                    .filter(cat -> !cat.isSystemCategory())
                    .forEach(cat -> result.add(convertToDTOWithSavedStatus(cat, userId, false)));

            log.info("   ✅ Found {} owned categories for user {}", result.size(), userId);
            return result;

        } catch (Exception e) {
            log.error("❌ Error in getMyCategoriesForFlashcardCreation for user {}: {}", userId, e.getMessage(), e);
            return new ArrayList<>();
        }
    }

    // ==================== CLASS CATEGORY MANAGEMENT ====================

    /**
     * ✅ FIXED: Giữ nguyên signature gốc (3 tham số) để tương thích với Controller
     * Trả về Category thay vì void
     */
    @Transactional
    public Category addCategoryToClass(Long categoryId, Long classId, Long userId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

        com.tieuluan.backend.model.Class classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Lớp học không tồn tại"));

        if (!classEntity.getOwnerId().equals(userId)) {
            throw new RuntimeException("Bạn không phải chủ lớp học này");
        }

        category.setClassId(classId);

        // ✅ Đảm bảo có shareToken khi thêm vào lớp
        if (category.getShareToken() == null || category.getShareToken().isEmpty()) {
            category.setShareToken(generateShareToken());
            log.info("✅ Generated shareToken for category {} when adding to class", categoryId);
        }

        Category saved = categoryRepository.save(category);
        log.info("✅ Added category {} to class {}", categoryId, classId);
        return saved;
    }

    /**
     * ✅ FIXED: Giữ nguyên signature gốc (4 tham số với isAdmin)
     */
    @Transactional
    public void removeCategoryFromClass(Long categoryId, Long classId, Long userId, boolean isAdmin) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

        com.tieuluan.backend.model.Class classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Lớp học không tồn tại"));

        if (!isAdmin && !classEntity.getOwnerId().equals(userId)) {
            throw new RuntimeException("Bạn không phải chủ lớp học này");
        }

        if (category.getClassId() == null || !category.getClassId().equals(classId)) {
            throw new RuntimeException("Category không thuộc lớp này");
        }

        category.setClassId(null);
        categoryRepository.save(category);
        log.info("✅ Removed category {} from class {}", categoryId, classId);
    }
}