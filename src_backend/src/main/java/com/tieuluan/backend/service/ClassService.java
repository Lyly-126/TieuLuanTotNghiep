package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.model.ClassMember;
import com.tieuluan.backend.model.ClassMemberId;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.ClassRepository;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.UserRepository;           // ← THÊM
import com.tieuluan.backend.repository.ClassMemberRepository;   // ← THÊM
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.UUID;

/**
 * ClassService - ONE-TO-MANY Architecture
 * ✅ Use CategoryRepository.findByClassId() instead of ClassSetRepository
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ClassService {

    private final ClassRepository classRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;              // ← THÊM
    private final ClassMemberRepository classMemberRepository; // ← THÊM

    @Transactional
    public Class createClass(String name, String description, Long teacherId) {
        String inviteCode = generateInviteCode();
        while (classRepository.findByInviteCode(inviteCode).isPresent()) {
            inviteCode = generateInviteCode();
        }

        Class clazz = new Class();
        clazz.setName(name);
        clazz.setDescription(description);
        clazz.setOwnerId(teacherId);
        clazz.setInviteCode(inviteCode);
        clazz.setIsPublic(false);
        clazz.setCreatedAt(ZonedDateTime.now());
        clazz.setUpdatedAt(ZonedDateTime.now());

        Class saved = classRepository.save(clazz);
        log.info("✅ Created class: {} by teacher {}", name, teacherId);
        return saved;
    }

    public List<Class> getClassesByTeacher(Long teacherId) {
        return classRepository.findByOwnerId(teacherId);
    }

    public Class getClassById(Long classId, Long userId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (isAdmin || clazz.isOwnedBy(userId)) {
            return clazz;
        }

        throw new RuntimeException("Bạn không có quyền xem lớp này");
    }

    @Transactional
    public Class updateClass(Long classId, String name, String description,
                             Long teacherId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!isAdmin && !clazz.isOwnedBy(teacherId)) {
            throw new RuntimeException("Bạn không có quyền sửa lớp này");
        }

        if (name != null && !name.trim().isEmpty()) {
            clazz.setName(name.trim());
        }
        if (description != null) {
            clazz.setDescription(description);
        }
        clazz.setUpdatedAt(ZonedDateTime.now());

        return classRepository.save(clazz);
    }

    @Transactional
    public void deleteClass(Long classId, Long userId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!isAdmin && !clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền xóa lớp này");
        }

        // ✅ FIXED: Use CategoryRepository
        long categoryCount = categoryRepository.countByClassId(classId);
        if (categoryCount > 0) {
            throw new RuntimeException("Không thể xóa lớp có " + categoryCount + " category");
        }

        classRepository.delete(clazz);
        log.info("✅ Deleted class {}", classId);
    }

    public List<Class> getAllClasses() {
        return classRepository.findAll();
    }

    public List<Class> searchClasses(String keyword, Long teacherId) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return classRepository.findByOwnerId(teacherId);
        }
        return classRepository.findByNameContainingIgnoreCase(keyword).stream()
                .filter(c -> c.isOwnedBy(teacherId))
                .toList();
    }

    public boolean isClassOwner(Long classId, Long teacherId) {
        return classRepository.existsByIdAndOwnerId(classId, teacherId);
    }

    /**
     * ✅ FIXED: Use CategoryRepository.countByClassId()
     */
    public long getCategoryCountInClass(Long classId) {
        return categoryRepository.countByClassId(classId);
    }

    public Class findByInviteCode(String inviteCode) {
        return classRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new RuntimeException("Mã lớp không hợp lệ"));
    }

    private String generateInviteCode() {
        return UUID.randomUUID().toString()
                .replace("-", "")
                .substring(0, 8)
                .toUpperCase();
    }

    @Transactional
    public void addMemberByEmail(Long classId, String email, String currentUsername) {
        // Kiểm tra class có tồn tại không
        Class classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Kiểm tra quyền - chỉ owner mới được thêm member
        User currentUser = userRepository.findByEmail(currentUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user hiện tại"));

        if (!classEntity.getOwnerId().equals(currentUser.getId())) {
            throw new RuntimeException("Bạn không có quyền thêm thành viên vào lớp này");
        }

        // Tìm user theo email
        User userToAdd = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với email: " + email));

        // Kiểm tra xem user đã là member chưa
        ClassMemberId memberId = new ClassMemberId(classId, userToAdd.getId());
        if (classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Người dùng đã là thành viên của lớp");
        }

        // ✅ FIXED: Use @EmbeddedId approach
        ClassMember newMember = new ClassMember();
        newMember.setId(memberId);                    // ✅ Set the embedded ID
        newMember.setClassEntity(classEntity);        // ✅ Set the relationship
        newMember.setUser(userToAdd);                 // ✅ Set the relationship
        newMember.setRole("STUDENT");                 // ✅ String, not enum
        newMember.setJoinedAt(LocalDateTime.now());   // ✅ LocalDateTime

        classMemberRepository.save(newMember);

        log.info("✅ Added member {} to class {}", email, classId);
    }
}