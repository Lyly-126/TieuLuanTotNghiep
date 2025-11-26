package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.ClassRepository;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ClassService {

    private final ClassRepository classRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;

    /**
     * ✅ TEACHER: Tạo lớp học mới
     */
    @Transactional
    public Class createClass(String name, String description, Long teacherId) {
        User teacher = userRepository.findById(teacherId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy giáo viên"));

        // ✅ FIXED: Check role trực tiếp
        if (teacher.getRole() != User.UserRole.TEACHER) {
            throw new RuntimeException("Chỉ giáo viên mới có thể tạo lớp học");
        }

        if (name == null || name.trim().isEmpty()) {
            throw new RuntimeException("Tên lớp không được để trống");
        }

        Class clazz = new Class();
        clazz.setName(name.trim());
        clazz.setDescription(description);
        clazz.setOwnerId(teacherId);

        Class saved = classRepository.save(clazz);
        log.info("✅ Teacher {} created class: {}", teacher.getEmail(), name);

        return saved;
    }

    /**
     * ✅ Lấy tất cả lớp của teacher
     */
    public List<Class> getClassesByTeacher(Long teacherId) {
        User teacher = userRepository.findById(teacherId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy giáo viên"));

        // ✅ FIXED: Check role trực tiếp
        if (teacher.getRole() != User.UserRole.TEACHER) {
            throw new RuntimeException("User không phải giáo viên");
        }

        return classRepository.findByOwnerId(teacherId);
    }

    /**
     * ✅ Lấy chi tiết lớp (với kiểm tra quyền)
     */
    public Class getClassById(Long classId, Long userId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Admin xem được tất cả
        if (isAdmin) {
            return clazz;
        }

        // Teacher owner xem được
        if (clazz.isOwnedBy(userId)) {
            return clazz;
        }

        // TODO: Sau này thêm logic cho học sinh (khi có ClassMember table)
        throw new RuntimeException("Bạn không có quyền xem lớp này");
    }

    /**
     * ✅ TEACHER: Cập nhật thông tin lớp
     */
    @Transactional
    public Class updateClass(Long classId, String name, String description, Long teacherId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Kiểm tra quyền
        if (!isAdmin && !clazz.isOwnedBy(teacherId)) {
            throw new RuntimeException("Bạn không có quyền sửa lớp này");
        }

        if (name != null && !name.trim().isEmpty()) {
            clazz.setName(name.trim());
        }

        if (description != null) {
            clazz.setDescription(description);
        }

        Class updated = classRepository.save(clazz);
        log.info("✅ Updated class {}: {}", classId, name);

        return updated;
    }

    /**
     * ✅ TEACHER: Xóa lớp học
     */
    @Transactional
    public void deleteClass(Long classId, Long userId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Kiểm tra quyền
        if (!isAdmin && !clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền xóa lớp này");
        }

        // Kiểm tra có category nào đang thuộc lớp này không
        long categoryCount = categoryRepository.findByClassId(classId).size();
        if (categoryCount > 0) {
            throw new RuntimeException("Không thể xóa lớp có " + categoryCount + " category. Vui lòng xóa categories trước.");
        }

        classRepository.delete(clazz);
        log.info("✅ Deleted class {}: {}", classId, clazz.getName());
    }

    /**
     * ✅ ADMIN: Lấy tất cả lớp học
     */
    public List<Class> getAllClasses() {
        return classRepository.findAll();
    }

    /**
     * ✅ Search lớp học theo tên
     */
    public List<Class> searchClasses(String keyword, Long teacherId) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return classRepository.findByOwnerId(teacherId);
        }

        List<Class> allMatches = classRepository.findByNameContainingIgnoreCase(keyword);

        // Chỉ trả về lớp của teacher này
        return allMatches.stream()
                .filter(c -> c.isOwnedBy(teacherId))
                .toList();
    }

    /**
     * ✅ Kiểm tra teacher có sở hữu lớp không
     */
    public boolean isClassOwner(Long classId, Long teacherId) {
        return classRepository.existsByIdAndOwnerId(classId, teacherId);
    }

    /**
     * ✅ Lấy số lượng categories trong lớp
     */
    public long getCategoryCountInClass(Long classId) {
        return categoryRepository.findByClassId(classId).size();
    }
}