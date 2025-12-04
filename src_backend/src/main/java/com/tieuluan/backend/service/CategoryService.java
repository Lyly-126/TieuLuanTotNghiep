package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.ClassRepository;
import com.tieuluan.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * CategoryService - ONE-TO-MANY Architecture
 * ✅ Category has classId (nullable)
 * ✅ 1 category → 0 or 1 class
 * ✅ NO ClassSet!
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final ClassRepository classRepository;
    private final UserRepository userRepository;

    /**
     * ✅ ADMIN: Tạo category hệ thống
     */
    @Transactional
    public Category createSystemCategory(String name) {
        if (categoryRepository.existsByName(name)) {
            throw new RuntimeException("Tên category đã tồn tại");
        }

        Category category = new Category();
        category.setName(name);
        category.setIsSystem(true);
        category.setOwnerUserId(null);
        category.setClassId(null);  // ✅ Độc lập
        category.setVisibility("PUBLIC");

        log.info("✅ Created system category: {}", name);
        return categoryRepository.save(category);
    }

    /**
     * ✅ USER: Tạo category cá nhân (PRIVATE, độc lập)
     */
    @Transactional
    public Category createUserCategory(String name, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // Check duplicate name cho user này
        List<Category> userCategories = categoryRepository.findByOwnerUserId(userId);
        boolean nameExists = userCategories.stream()
                .anyMatch(c -> c.getName().equalsIgnoreCase(name));

        if (nameExists) {
            throw new RuntimeException("Bạn đã có category với tên này");
        }

        Category category = new Category();
        category.setName(name);
        category.setIsSystem(false);
        category.setOwnerUserId(userId);
        category.setClassId(null);  // ✅ Độc lập
        category.setVisibility("PRIVATE"); // Normal user: PRIVATE only

        log.info("✅ User {} created personal category: {}", user.getEmail(), name);
        return categoryRepository.save(category);
    }

    /**
     * ✅ TEACHER/PREMIUM: Tạo category PUBLIC (có thể share)
     */
    @Transactional
    public Category createShareableCategory(String name, Long userId, String visibility) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // Check role: chỉ Teacher hoặc Premium mới được tạo PUBLIC
        if (user.getRole() != User.UserRole.TEACHER &&
                user.getRole() != User.UserRole.PREMIUM_USER) {
            throw new RuntimeException("Chỉ Teacher/Premium mới có thể tạo category PUBLIC");
        }

        // Check duplicate name
        List<Category> userCategories = categoryRepository.findByOwnerUserId(userId);
        boolean nameExists = userCategories.stream()
                .anyMatch(c -> c.getName().equalsIgnoreCase(name));

        if (nameExists) {
            throw new RuntimeException("Bạn đã có category với tên này");
        }

        Category category = new Category();
        category.setName(name);
        category.setIsSystem(false);
        category.setOwnerUserId(userId);
        category.setClassId(null);  // ✅ Độc lập
        category.setVisibility(visibility); // PUBLIC, PRIVATE, etc.

        log.info("✅ User {} created {} category: {}",
                user.getEmail(), visibility, name);
        return categoryRepository.save(category);
    }

    /**
     * ✅ ADD category to class (ONE-TO-MANY - set classId)
     * Replaces old addCategoryToClass with ClassSet
     */
    @Transactional
    public Category addCategoryToClass(Long categoryId, Long classId, Long userId) {
        // Verify category exists
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy category"));

        // Verify class exists
        com.tieuluan.backend.model.Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Check permission: user must be class owner
        if (!clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không phải chủ sở hữu lớp này");
        }

        // ✅ Check if category already in another class
        if (category.getClassId() != null && !category.getClassId().equals(classId)) {
            throw new RuntimeException("Category đã thuộc lớp khác. 1 category chỉ được nằm trong 1 lớp.");
        }

        // Check if already in this class
        if (category.getClassId() != null && category.getClassId().equals(classId)) {
            throw new RuntimeException("Category đã có trong lớp này");
        }

        // ✅ Set classId (ONE-TO-MANY)
        category.setClassId(classId);
        Category updated = categoryRepository.save(category);

        log.info("✅ Added category {} to class {} by user {}",
                category.getName(), clazz.getName(), userId);
        return updated;
    }

    /**
     * ✅ GET categories in a class (ONE-TO-MANY)
     */
    public List<Category> getCategoriesForClass(Long classId) {
        return categoryRepository.findByClassId(classId);
    }

    /**
     * ✅ Lấy tất cả system categories
     */
    public List<Category> getSystemCategories() {
        return categoryRepository.findByIsSystemTrue();
    }

    /**
     * ✅ Lấy categories của user (chỉ owned)
     */
    public List<Category> getUserOwnedCategories(Long userId) {
        return categoryRepository.findByOwnerUserId(userId);
    }

    /**
     * ✅ Lấy PUBLIC categories (có thể share/add to class)
     */
    public List<Category> getPublicCategories() {
        return categoryRepository.findPublicCategories();
    }

    /**
     * ✅ Lấy categories available cho user
     * (System + Own + Public)
     */
    public List<Category> getAvailableCategories(Long userId) {
        return categoryRepository.findAvailableForUser(userId);
    }

    /**
     * ✅ Xóa category (check dependencies)
     */
    @Transactional
    public void deleteCategory(Long categoryId, Long userId, boolean isAdmin) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy category"));

        // System category: chỉ admin mới xóa được
        if (category.isSystemCategory() && !isAdmin) {
            throw new RuntimeException("Chỉ admin mới có thể xóa category hệ thống");
        }

        // User category: chỉ owner hoặc admin mới xóa được
        if (!isAdmin && !category.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền xóa category này");
        }

        // Check flashcards
        long flashcardCount = categoryRepository.countFlashcardsInCategory(categoryId);
        if (flashcardCount > 0) {
            throw new RuntimeException(
                    "Không thể xóa category có " + flashcardCount + " flashcard");
        }

        categoryRepository.delete(category);
        log.info("✅ Deleted category: {} by user {}", category.getName(), userId);
    }

    /**
     * ✅ Cập nhật category name
     */
    @Transactional
    public Category updateCategory(Long categoryId, String newName, Long userId, boolean isAdmin) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy category"));

        // Kiểm tra quyền
        if (!isAdmin && !category.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền sửa category này");
        }

        if (newName == null || newName.trim().isEmpty()) {
            throw new RuntimeException("Tên category không được để trống");
        }

        category.setName(newName.trim());
        Category updated = categoryRepository.save(category);

        log.info("✅ Updated category {} to '{}'", categoryId, newName);
        return updated;
    }

    /**
     * ✅ Kiểm tra user có quyền sử dụng category không
     */
    public boolean canUserAccessCategory(Long categoryId, Long userId) {
        return categoryRepository.isAccessibleByUser(categoryId, userId);
    }

    /**
     * ✅ Lấy category by ID (với kiểm tra quyền)
     */
    public Category getCategoryById(Long categoryId, Long userId, boolean isAdmin) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy category"));

        // Admin xem được tất cả
        if (isAdmin) {
            return category;
        }

        // System category: ai cũng xem được
        if (category.isSystemCategory()) {
            return category;
        }

        // PUBLIC category: ai cũng xem được
        if (category.isPublic()) {
            return category;
        }

        // PRIVATE: chỉ owner xem được
        if (category.isOwnedBy(userId)) {
            return category;
        }

        throw new RuntimeException("Bạn không có quyền xem category này");
    }

    /**
     * ✅ Remove category from class (set classId = null)
     */
    @Transactional
    public void removeCategoryFromClass(Long categoryId, Long classId, Long userId, boolean isAdmin) {
        // Verify category
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy category"));

        // Verify class exists
        com.tieuluan.backend.model.Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Check permission
        if (!isAdmin && !clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền xóa category khỏi lớp này");
        }

        // Check if in this class
        if (category.getClassId() == null || !category.getClassId().equals(classId)) {
            throw new RuntimeException("Category không có trong lớp này");
        }

        // ✅ Remove from class (set classId = null)
        category.setClassId(null);
        categoryRepository.save(category);

        log.info("✅ Removed category {} from class {} by user {}",
                categoryId, classId, userId);
    }


}
