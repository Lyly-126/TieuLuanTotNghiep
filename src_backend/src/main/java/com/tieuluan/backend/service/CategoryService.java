package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.ClassRepository;
import com.tieuluan.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

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
        category.setClassId(null);

        log.info("✅ Created system category: {}", name);
        return categoryRepository.save(category);
    }

    /**
     * ✅ USER: Tạo category cá nhân
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
        category.setClassId(null);

        log.info("✅ User {} created personal category: {}", user.getEmail(), name);
        return categoryRepository.save(category);
    }

    /**
     * ✅ TEACHER: Tạo category cho lớp học
     */
    @Transactional
    public Category createClassCategory(String name, Long classId, Long teacherId) {
        // Kiểm tra teacher có quyền teacher không
        User teacher = userRepository.findById(teacherId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy giáo viên"));

        // ✅ FIXED: Check role thay vì isTeacher()
        if (teacher.getRole() != User.UserRole.TEACHER) {
            throw new RuntimeException("Chỉ giáo viên mới có thể tạo category cho lớp");
        }

        // Kiểm tra lớp có tồn tại và thuộc teacher không
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!clazz.isOwnedBy(teacherId)) {
            throw new RuntimeException("Bạn không phải chủ sở hữu lớp này");
        }

        // Check duplicate name trong lớp này
        List<Category> classCategories = categoryRepository.findByClassId(classId);
        boolean nameExists = classCategories.stream()
                .anyMatch(c -> c.getName().equalsIgnoreCase(name));

        if (nameExists) {
            throw new RuntimeException("Lớp này đã có category với tên này");
        }

        Category category = new Category();
        category.setName(name);
        category.setIsSystem(false);
        category.setOwnerUserId(teacherId);
        category.setClassId(classId);

        log.info("✅ Teacher {} created category '{}' for class '{}'",
                teacher.getEmail(), name, clazz.getName());
        return categoryRepository.save(category);
    }

    /**
     * ✅ Lấy categories available cho user
     * (System categories + User's own categories)
     */
    public List<Category> getAvailableCategories(Long userId) {
        return categoryRepository.findAvailableForUser(userId);
    }

    /**
     * ✅ Lấy categories của 1 lớp
     * (System categories + Class categories)
     */
    public List<Category> getCategoriesForClass(Long classId) {
        return categoryRepository.findAvailableForClass(classId);
    }

    /**
     * ✅ Lấy tất cả system categories
     */
    public List<Category> getSystemCategories() {
        return categoryRepository.findByIsSystemTrue();
    }

    /**
     * ✅ Lấy categories của user (chỉ owned, không bao gồm system)
     */
    public List<Category> getUserOwnedCategories(Long userId) {
        return categoryRepository.findByOwnerUserId(userId);
    }

    /**
     * ✅ Lấy categories của teacher (bao gồm class categories)
     */
    public List<Category> getTeacherCategories(Long teacherId) {
        User teacher = userRepository.findById(teacherId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy giáo viên"));

        // ✅ FIXED: Check role thay vì isTeacher()
        if (teacher.getRole() != User.UserRole.TEACHER) {
            throw new RuntimeException("User không phải giáo viên");
        }

        return categoryRepository.findByTeacherId(teacherId);
    }

    /**
     * ✅ Xóa category (chỉ owner hoặc admin)
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

        // Kiểm tra có flashcard nào đang dùng không
        long flashcardCount = categoryRepository.countFlashcardsInCategory(categoryId);
        if (flashcardCount > 0) {
            throw new RuntimeException("Không thể xóa category có " + flashcardCount + " flashcard");
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

        // User category: chỉ owner xem được
        if (category.isOwnedBy(userId)) {
            return category;
        }

        throw new RuntimeException("Bạn không có quyền xem category này");
    }
}