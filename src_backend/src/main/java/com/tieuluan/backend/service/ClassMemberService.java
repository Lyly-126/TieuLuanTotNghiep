package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.ClassMemberDTO;
import com.tieuluan.backend.model.Class;
import com.tieuluan.backend.model.ClassMember;
import com.tieuluan.backend.model.ClassMemberId;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.ClassMemberRepository;
import com.tieuluan.backend.repository.ClassRepository;
import com.tieuluan.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ClassMemberService {

    private final ClassMemberRepository classMemberRepository;
    private final ClassRepository classRepository;
    private final UserRepository userRepository;

    @Transactional
    public ClassMemberDTO addMember(Long classId, Long userId, Long requesterId) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!clazz.isOwnedBy(requesterId)) {
            throw new RuntimeException("Bạn không có quyền thêm thành viên vào lớp này");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Người dùng đã là thành viên của lớp này");
        }

        ClassMember member = new ClassMember();
        member.setId(memberId);
        member.setClassEntity(clazz);
        member.setUser(user);
        member.setRole("STUDENT");
        member.setJoinedAt(LocalDateTime.now());

        ClassMember saved = classMemberRepository.save(member);
        log.info("✅ Added user {} to class {}", user.getEmail(), clazz.getName());

        return new ClassMemberDTO(saved);
    }

    @Transactional
    public void removeMember(Long classId, Long userId, Long requesterId) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!clazz.isOwnedBy(requesterId)) {
            throw new RuntimeException("Bạn không có quyền xóa thành viên khỏi lớp này");
        }

        if (userId.equals(clazz.getOwnerId())) {
            throw new RuntimeException("Không thể xóa giáo viên chủ nhiệm khỏi lớp");
        }

        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (!classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Người dùng không phải thành viên của lớp này");
        }

        classMemberRepository.deleteById(memberId);
        log.info("✅ Removed user {} from class {}", userId, clazz.getName());
    }

    @Transactional
    public void leaveClass(Long classId, Long userId) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (userId.equals(clazz.getOwnerId())) {
            throw new RuntimeException("Giáo viên chủ nhiệm không thể rời khỏi lớp");
        }

        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (!classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn không phải thành viên của lớp này");
        }

        classMemberRepository.deleteById(memberId);
        log.info("✅ User {} left class {}", userId, clazz.getName());
    }

    /**
     * ✅ FIXED: Dùng findByIdClassId để query theo classId
     */
    public List<ClassMemberDTO> getClassMembers(Long classId, Long requesterId) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        ClassMemberId memberId = new ClassMemberId(classId, requesterId);
        if (!clazz.isOwnedBy(requesterId) && !classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn không có quyền xem danh sách thành viên");
        }

        // ✅ FIXED: Dùng findByIdClassId thay vì findByIdUserId
        List<ClassMember> members = classMemberRepository.findByIdClassId(classId);

        log.info("✅ Found {} members for class {}", members.size(), classId);

        return members.stream()
                .map(ClassMemberDTO::new)
                .collect(Collectors.toList());
    }

    /**
     * ✅ FIXED: Dùng findByIdUserId để query theo userId
     */
    public List<Long> getClassIdsByUser(Long userId) {
        // ✅ Dùng findByIdUserId cho userId
        List<ClassMember> members = classMemberRepository.findByIdUserId(userId);
        return members.stream()
                .map(member -> member.getId().getClassId())
                .collect(Collectors.toList());
    }

    public boolean isMember(Long classId, Long userId) {
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        return classMemberRepository.existsById(memberId);
    }

    /**
     * ✅ Count approved members
     */
    public long countMembers(Long classId) {
        return classMemberRepository.countByIdClassIdAndStatusApproved(classId);
    }

    /**
     * ✅ JOIN BY INVITE CODE - Với approval logic
     */
    @Transactional
    public ClassMemberDTO joinByInviteCode(String inviteCode, Long userId) {
        // 1. Tìm lớp học
        Class clazz = classRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new RuntimeException("Mã lớp không hợp lệ"));

        // ✅ FIX 1: KIỂM TRA OWNER KHÔNG ĐƯỢC TỰ JOIN
        if (clazz.getOwnerId().equals(userId)) {
            throw new RuntimeException("Bạn là chủ lớp này, không cần tham gia");
        }

        // 2. Tìm user
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // 3. Kiểm tra đã là member chưa
        ClassMemberId memberId = new ClassMemberId(clazz.getId(), userId);
        if (classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn đã là thành viên của lớp này");
        }

        // 4. Tạo member với status phù hợp
        ClassMember member = new ClassMember();
        member.setId(memberId);
        member.setClassEntity(clazz);
        member.setUser(user);
        member.setRole("STUDENT");
        member.setJoinedAt(LocalDateTime.now());

        // Logic approval
        if (Boolean.TRUE.equals(clazz.getIsPublic())) {
            member.setStatus("APPROVED");
            log.info("✅ User {} joined PUBLIC class {} - AUTO APPROVED",
                    user.getEmail(), clazz.getName());
        } else {
            member.setStatus("PENDING");
            log.info("⏳ User {} requested to join PRIVATE class {} - PENDING APPROVAL",
                    user.getEmail(), clazz.getName());
        }

        ClassMember saved = classMemberRepository.save(member);
        return new ClassMemberDTO(saved);
    }

    /**
     * ✅ APPROVE MEMBER - Teacher duyệt thành viên
     */
    @Transactional
    public ClassMemberDTO approveMember(Long classId, Long userId, Long teacherId) {
        // Kiểm tra quyền
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!clazz.isOwnedBy(teacherId)) {
            throw new RuntimeException("Bạn không có quyền duyệt thành viên");
        }

        // Lấy member
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        ClassMember member = classMemberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu tham gia"));

        if (!"PENDING".equals(member.getStatus())) {
            throw new RuntimeException("Yêu cầu này đã được xử lý");
        }

        // Approve
        member.setStatus("APPROVED");
        ClassMember saved = classMemberRepository.save(member);

        log.info("✅ Teacher {} APPROVED user {} for class {}",
                teacherId, userId, classId);

        return new ClassMemberDTO(saved);
    }

    /**
     * ✅ REJECT MEMBER - Teacher từ chối thành viên
     */
    @Transactional
    public void rejectMember(Long classId, Long userId, Long teacherId) {
        // Kiểm tra quyền
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!clazz.isOwnedBy(teacherId)) {
            throw new RuntimeException("Bạn không có quyền từ chối thành viên");
        }

        // Lấy member
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        ClassMember member = classMemberRepository.findById(memberId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy yêu cầu tham gia"));

        if (!"PENDING".equals(member.getStatus())) {
            throw new RuntimeException("Yêu cầu này đã được xử lý");
        }

        // Xóa luôn (hoặc set REJECTED nếu muốn giữ lịch sử)
        classMemberRepository.deleteById(memberId);

        log.info("❌ Teacher {} REJECTED user {} for class {}",
                teacherId, userId, classId);
    }

    /**
     * ✅ GET PENDING MEMBERS - Lấy danh sách chờ duyệt
     */
    public List<ClassMemberDTO> getPendingMembers(Long classId, Long teacherId) {
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        if (!clazz.isOwnedBy(teacherId)) {
            throw new RuntimeException("Bạn không có quyền xem danh sách chờ duyệt");
        }

        List<ClassMember> pendingMembers = classMemberRepository
                .findByClassIdAndStatus(classId, "PENDING");

        return pendingMembers.stream()
                .map(ClassMemberDTO::new)
                .collect(Collectors.toList());
    }

    /**
     * ✅ Teacher thêm member trực tiếp vào lớp (auto APPROVED)
     */
    @Transactional
    public ClassMemberDTO addMemberByTeacher(Long classId, Long userId, Long teacherId, String role) {
        // 1. Kiểm tra lớp học
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // 2. Kiểm tra quyền: Chỉ owner mới được thêm member
        if (!clazz.isOwnedBy(teacherId)) {
            throw new RuntimeException("Bạn không có quyền thêm thành viên vào lớp này");
        }

        // 3. Không thể thêm chính mình
        if (userId.equals(teacherId)) {
            throw new RuntimeException("Bạn không thể thêm chính mình vào lớp");
        }

        // 4. Kiểm tra user tồn tại
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // 5. Kiểm tra đã là member chưa
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Người dùng đã là thành viên của lớp này");
        }

        // 6. Tạo member với status APPROVED
        ClassMember member = new ClassMember();
        member.setId(memberId);
        member.setClassEntity(clazz);
        member.setUser(user);
        member.setRole(role != null ? role : "STUDENT");
        member.setStatus("APPROVED");
        member.setJoinedAt(LocalDateTime.now());

        ClassMember saved = classMemberRepository.save(member);

        log.info("✅ Teacher {} added user {} to class {} as {}",
                teacherId, user.getEmail(), clazz.getName(), role);

        return new ClassMemberDTO(saved);
    }

    /**
     * ✅ GET APPROVED MEMBERS - Chỉ lấy members đã được duyệt
     */
    public List<ClassMemberDTO> getApprovedMembers(Long classId) {
        List<ClassMember> approvedMembers = classMemberRepository
                .findByClassIdAndStatus(classId, "APPROVED");

        return approvedMembers.stream()
                .map(ClassMemberDTO::new)
                .collect(Collectors.toList());
    }

    /**
     * ✅ COUNT APPROVED MEMBERS
     */
    public long countApprovedMembers(Long classId) {
        return classMemberRepository.countByIdClassIdAndStatusApproved(classId);
    }
}