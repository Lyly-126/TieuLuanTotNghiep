package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.model.ClassMember;
import com.tieuluan.backend.model.ClassMemberId;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.repository.ClassRepository;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.repository.ClassMemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

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
    private final UserRepository userRepository;
    private final ClassMemberRepository classMemberRepository;

    // ✅ SỬA: Thêm parameter Boolean isPublic
    @Transactional
    public Class createClass(String name, String description, Long teacherId, Boolean isPublic) {
        String inviteCode = generateInviteCode();
        while (classRepository.findByInviteCode(inviteCode).isPresent()) {
            inviteCode = generateInviteCode();
        }

        Class clazz = new Class();
        clazz.setName(name);
        clazz.setDescription(description);
        clazz.setOwnerId(teacherId);
        clazz.setInviteCode(inviteCode);
        clazz.setIsPublic(isPublic != null ? isPublic : false);
        clazz.setCreatedAt(ZonedDateTime.now());
        clazz.setUpdatedAt(ZonedDateTime.now());

        Class saved = classRepository.save(clazz);
        log.info("✅ Created class: {} by teacher {} (isPublic: {})", name, teacherId, isPublic);
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

    // ✅ SỬA: Thêm parameter Boolean isPublic
    @Transactional
    public Class updateClass(Long classId, String name, String description,
                             Long teacherId, boolean isAdmin, Boolean isPublic) {
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
        if (isPublic != null) {
            clazz.setIsPublic(isPublic);
            log.info("✅ Class {} visibility changed to: {}", classId, isPublic ? "PUBLIC" : "PRIVATE");
        }
        clazz.setUpdatedAt(ZonedDateTime.now());

        return classRepository.save(clazz);
    }

    // ✅ FIX: Cho phép xóa lớp có categories (categories sẽ tự động có classId = NULL)
    @Transactional
    public void deleteClass(Long classId, Long userId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!isAdmin && !clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền xóa lớp này");
        }

        // ✅ BỎ VALIDATION - Cho phép xóa lớp có categories
        // Database có ON DELETE SET NULL → categories sẽ tự động có classId = NULL

        classRepository.delete(clazz);
        log.info("✅ Deleted class {} (categories become independent)", classId);
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
        newMember.setId(memberId);
        newMember.setClassEntity(classEntity);
        newMember.setUser(userToAdd);
        newMember.setRole("STUDENT");
        newMember.setJoinedAt(LocalDateTime.now());

        classMemberRepository.save(newMember);

        log.info("✅ Added member {} to class {}", email, classId);
    }


    /**
     * ✅ LEAVE CLASS - Student rời lớp
     * Thêm method này vào ClassService.java
     */
    @Transactional
    public void leaveClass(Long classId, Long userId) {
        // Kiểm tra class có tồn tại không
        Class classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Lớp học không tồn tại"));

        // Kiểm tra user có phải owner không
        if (classEntity.getOwnerId() != null && classEntity.getOwnerId().equals(userId)) {
            throw new RuntimeException("Bạn là chủ lớp, không thể rời lớp");
        }

        // Xóa khỏi classMembers
        ClassMemberId memberId = new ClassMemberId(classId, userId);

        if (!classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn chưa tham gia lớp này");
        }

        classMemberRepository.deleteById(memberId);
        log.info("✅ User {} left class {}", userId, classId);
    }

    /**
     * ✅ CHECK IF USER IS OWNER
     * Thêm method này vào ClassService.java
     */
    public boolean isOwner(Long classId, Long userId) {
        Class classEntity = classRepository.findById(classId).orElse(null);
        if (classEntity == null) {
            return false;
        }
        return classEntity.getOwnerId() != null && classEntity.getOwnerId().equals(userId);
    }

    /**
     * ✅ CHECK IF USER IS MEMBER
     * Thêm method này vào ClassService.java
     */
    public boolean isMember(Long classId, Long userId) {
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        return classMemberRepository.existsById(memberId);
    }

    /**
     * ✅ SEARCH BY INVITE CODE - EXACT MATCH
     * Tìm kiếm TUYỆT ĐỐI theo invite code
     * Trả về TẤT CẢ lớp (public + private) nếu mã khớp chính xác
     */
    public List<Class> searchByInviteCode(String inviteCode) {
        if (inviteCode == null || inviteCode.trim().isEmpty()) {
            return List.of();
        }

        // ✅ EXACT MATCH - Không phân biệt hoa thường
        String cleanCode = inviteCode.trim().toUpperCase();

        Optional<Class> result = classRepository.findByInviteCode(cleanCode);

        // Trả về list (có thể rỗng hoặc có 1 phần tử)
        return result.map(List::of).orElse(List.of());
    }

    /**
     * ✅ SEARCH CLASSES - Cập nhật logic
     * - Nếu là invite code (6-12 ký tự, chỉ gồm A-Z0-9) → exact match
     * - Nếu không phải invite code → fuzzy search trong name, description
     */
    public List<Class> searchPublicClasses(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return classRepository.findByIsPublicTrue();
        }

        String cleanKeyword = keyword.trim().toUpperCase();

        // ✅ KIỂM TRA XEM CÓ PHẢI INVITE CODE KHÔNG
        boolean isInviteCodePattern = cleanKeyword.matches("^[A-Z0-9]{6,12}$");

        if (isInviteCodePattern) {
            // ✅ EXACT MATCH - Tìm theo invite code (cả public + private)
            return searchByInviteCode(cleanKeyword);
        } else {
            // ✅ FUZZY MATCH - Tìm trong name, description (chỉ public)
            String lowerKeyword = keyword.toLowerCase().trim();
            List<Class> publicClasses = classRepository.findByIsPublicTrue();

            return publicClasses.stream()
                    .filter(c -> {
                        boolean matchName = c.getName().toLowerCase().contains(lowerKeyword);
                        boolean matchDesc = c.getDescription() != null &&
                                c.getDescription().toLowerCase().contains(lowerKeyword);
                        return matchName || matchDesc;
                    })
                    .collect(Collectors.toList());
        }
    }

    /**
     * ✅ FIX 3: REGENERATE INVITE CODE
     * Tạo mã mời mới cho lớp học
     */
    @Transactional
    public Class regenerateInviteCode(Long classId, Long userId, boolean isAdmin) {
        // Kiểm tra lớp tồn tại
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Kiểm tra quyền
        if (!isAdmin && !clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền tạo lại mã mời");
        }

        // Tạo mã mới (đảm bảo unique)
        String newCode;
        int maxRetries = 10;
        int attempt = 0;

        do {
            newCode = Class.generateInviteCode();
            attempt++;

            if (attempt >= maxRetries) {
                throw new RuntimeException("Không thể tạo mã mời mới. Vui lòng thử lại.");
            }
        } while (classRepository.existsByInviteCode(newCode));

        // Lưu mã cũ để log
        String oldCode = clazz.getInviteCode();

        // Cập nhật mã mới
        clazz.setInviteCode(newCode);
        clazz.setUpdatedAt(ZonedDateTime.now());

        Class saved = classRepository.save(clazz);

        log.info("✅ Regenerated invite code for class {} - Old: {}, New: {}",
                classId, oldCode, newCode);

        return saved;
    }

    /**
     * ✅ GET CLASS BY ID FOR MEMBER
     * Cho phép member/owner/admin xem thông tin lớp
     * Method này KHÔNG check quyền - dùng khi đã xác nhận user là member
     */
    public Class getClassByIdForMember(Long classId) {
        return classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));
    }

    /**
     * ✅ GET JOINED CLASSES WITH FULL INFO
     * Lấy danh sách lớp mà user đã tham gia (APPROVED) với thông tin đầy đủ
     *
     * @param userId ID của user
     * @return List<Class> danh sách các lớp đã tham gia
     */
    public List<Class> getJoinedClassesByUser(Long userId) {
        // Lấy danh sách classId từ ClassMemberService
        List<Long> classIds = classMemberRepository.findByIdUserId(userId)
                .stream()
                .filter(member -> "APPROVED".equals(member.getStatus()))
                .map(member -> member.getId().getClassId())
                .collect(Collectors.toList());

        // Load thông tin đầy đủ của các lớp
        return classIds.stream()
                .map(classId -> classRepository.findById(classId).orElse(null))
                .filter(clazz -> clazz != null)
                .collect(Collectors.toList());
    }
}
