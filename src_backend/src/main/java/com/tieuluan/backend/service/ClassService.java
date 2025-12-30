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

        if (isAdmin) return clazz;
        if (clazz.isOwnedBy(userId)) return clazz;

        ClassMemberId memberId = new ClassMemberId(classId, userId);
        boolean isApprovedMember = classMemberRepository.findById(memberId)
                .map(member -> "APPROVED".equals(member.getStatus()))
                .orElse(false);
        if (isApprovedMember) return clazz;
        if (Boolean.TRUE.equals(clazz.getIsPublic())) return clazz;

        throw new RuntimeException("Bạn không có quyền xem lớp này");
    }

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

    @Transactional
    public void deleteClass(Long classId, Long userId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!isAdmin && !clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền xóa lớp này");
        }

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
        Class classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        User currentUser = userRepository.findByEmail(currentUsername)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user hiện tại"));

        if (!classEntity.getOwnerId().equals(currentUser.getId())) {
            throw new RuntimeException("Bạn không có quyền thêm thành viên vào lớp này");
        }

        User userToAdd = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng với email: " + email));

        ClassMemberId memberId = new ClassMemberId(classId, userToAdd.getId());
        if (classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Người dùng đã là thành viên của lớp");
        }

        ClassMember newMember = new ClassMember();
        newMember.setId(memberId);
        newMember.setClassEntity(classEntity);
        newMember.setUser(userToAdd);
        newMember.setRole("STUDENT");
        newMember.setJoinedAt(LocalDateTime.now());

        classMemberRepository.save(newMember);
        log.info("✅ Added member {} to class {}", email, classId);
    }

    @Transactional
    public void leaveClass(Long classId, Long userId) {
        Class classEntity = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Lớp học không tồn tại"));

        if (classEntity.getOwnerId() != null && classEntity.getOwnerId().equals(userId)) {
            throw new RuntimeException("Bạn là chủ lớp, không thể rời lớp");
        }

        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (!classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn chưa tham gia lớp này");
        }

        classMemberRepository.deleteById(memberId);
        log.info("✅ User {} left class {}", userId, classId);
    }

    public boolean isOwner(Long classId, Long userId) {
        Class classEntity = classRepository.findById(classId).orElse(null);
        if (classEntity == null) return false;
        return classEntity.getOwnerId() != null && classEntity.getOwnerId().equals(userId);
    }

    public boolean isMember(Long classId, Long userId) {
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        return classMemberRepository.existsById(memberId);
    }

    /**
     * ✅ SEARCH BY INVITE CODE - EXACT MATCH
     * Trả về TẤT CẢ lớp (public + private) nếu mã khớp chính xác
     */
    public List<Class> searchByInviteCode(String inviteCode) {
        if (inviteCode == null || inviteCode.trim().isEmpty()) {
            return List.of();
        }

        String cleanCode = inviteCode.trim().toUpperCase();
        Optional<Class> result = classRepository.findByInviteCode(cleanCode);
        return result.map(List::of).orElse(List.of());
    }

    /**
     * ✅ SEARCH CLASSES - CẢI TIẾN
     * - LUÔN THỬ EXACT MATCH INVITE CODE TRƯỚC
     * - Nếu tìm thấy → trả về lớp (cả public + private)
     * - Nếu không tìm thấy → fuzzy search trong name, description (chỉ public)
     */
    public List<Class> searchPublicClasses(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return classRepository.findByIsPublicTrue();
        }

        String cleanKeyword = keyword.trim();

        // ✅ BƯỚC 1: LUÔN THỬ TÌM THEO INVITE CODE TRƯỚC (EXACT MATCH)
        // Không cần check pattern - cứ thử tìm exact match
        Optional<Class> exactMatch = classRepository.findByInviteCode(cleanKeyword.toUpperCase());
        if (exactMatch.isPresent()) {
            log.info("✅ Found class by exact invite code: {}", cleanKeyword);
            return List.of(exactMatch.get());
        }

        // ✅ BƯỚC 2: NẾU KHÔNG TÌM THẤY → FUZZY SEARCH TRONG PUBLIC CLASSES
        String lowerKeyword = cleanKeyword.toLowerCase();
        List<Class> publicClasses = classRepository.findByIsPublicTrue();

        List<Class> results = publicClasses.stream()
                .filter(c -> {
                    boolean matchName = c.getName().toLowerCase().contains(lowerKeyword);
                    boolean matchDesc = c.getDescription() != null &&
                            c.getDescription().toLowerCase().contains(lowerKeyword);
                    // ✅ THÊM: Match invite code partial (cho trường hợp user nhập một phần mã)
                    boolean matchCode = c.getInviteCode() != null &&
                            c.getInviteCode().toLowerCase().contains(lowerKeyword);
                    return matchName || matchDesc || matchCode;
                })
                .collect(Collectors.toList());

        log.info("✅ Found {} public classes matching: {}", results.size(), keyword);
        return results;
    }

    @Transactional
    public Class regenerateInviteCode(Long classId, Long userId, boolean isAdmin) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!isAdmin && !clazz.isOwnedBy(userId)) {
            throw new RuntimeException("Bạn không có quyền tạo lại mã mời");
        }

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

        String oldCode = clazz.getInviteCode();
        clazz.setInviteCode(newCode);
        clazz.setUpdatedAt(ZonedDateTime.now());

        Class saved = classRepository.save(clazz);
        log.info("✅ Regenerated invite code for class {} - Old: {}, New: {}", classId, oldCode, newCode);

        return saved;
    }

    public Class getClassByIdForMember(Long classId) {
        return classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));
    }

    public List<Class> getJoinedClassesByUser(Long userId) {
        List<Long> classIds = classMemberRepository.findByIdUserId(userId)
                .stream()
                .filter(member -> "APPROVED".equals(member.getStatus()))
                .map(member -> member.getId().getClassId())
                .collect(Collectors.toList());

        return classIds.stream()
                .map(classId -> classRepository.findById(classId).orElse(null))
                .filter(clazz -> clazz != null)
                .collect(Collectors.toList());
    }

    public Class getClassByInviteCode(String inviteCode) {
        return classRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new IllegalArgumentException("Mã lớp không hợp lệ hoặc đã hết hạn"));
    }
}