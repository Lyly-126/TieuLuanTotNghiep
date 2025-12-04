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

    /**
     * ✅ Thêm học viên vào lớp (bởi teacher/owner)
     */
    @Transactional
    public ClassMemberDTO addMember(Long classId, Long userId, Long requesterId) {
        // Kiểm tra lớp tồn tại
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Kiểm tra quyền: chỉ owner mới được thêm member
        if (!clazz.isOwnedBy(requesterId)) {
            throw new RuntimeException("Bạn không có quyền thêm thành viên vào lớp này");
        }

        // Kiểm tra user tồn tại
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // ✅ FIXED: Check using composite ID
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Người dùng đã là thành viên của lớp này");
        }

        // ✅ FIXED: Tạo member mới với EmbeddedId
        ClassMember member = new ClassMember();
        member.setId(memberId);
        member.setClassEntity(clazz);
        member.setUser(user);
        member.setRole("STUDENT");              // ← String, not enum
        member.setJoinedAt(LocalDateTime.now()); // ← LocalDateTime, not ZonedDateTime

        ClassMember saved = classMemberRepository.save(member);
        log.info("✅ Added user {} to class {}", user.getEmail(), clazz.getName());

        return new ClassMemberDTO(saved);
    }

    /**
     * ✅ Xóa học viên khỏi lớp (bởi teacher/owner)
     */
    @Transactional
    public void removeMember(Long classId, Long userId, Long requesterId) {
        // Kiểm tra lớp tồn tại
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Kiểm tra quyền
        if (!clazz.isOwnedBy(requesterId)) {
            throw new RuntimeException("Bạn không có quyền xóa thành viên khỏi lớp này");
        }

        // Không cho phép xóa owner
        if (userId.equals(clazz.getOwnerId())) {
            throw new RuntimeException("Không thể xóa giáo viên chủ nhiệm khỏi lớp");
        }

        // ✅ FIXED: Delete using composite ID
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (!classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Người dùng không phải thành viên của lớp này");
        }

        classMemberRepository.deleteById(memberId);
        log.info("✅ Removed user {} from class {}", userId, clazz.getName());
    }

    /**
     * ✅ Tham gia lớp qua invite code (bởi student)
     */
    @Transactional
    public ClassMemberDTO joinByInviteCode(String inviteCode, Long userId) {
        // Tìm lớp theo invite code
        Class clazz = classRepository.findByInviteCode(inviteCode)
                .orElseThrow(() -> new RuntimeException("Mã lớp không hợp lệ"));

        // Kiểm tra user tồn tại
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // ✅ FIXED: Check using composite ID
        ClassMemberId memberId = new ClassMemberId(clazz.getId(), userId);
        if (classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn đã là thành viên của lớp này");
        }

        // ✅ FIXED: Tạo member mới
        ClassMember member = new ClassMember();
        member.setId(memberId);
        member.setClassEntity(clazz);
        member.setUser(user);
        member.setRole("STUDENT");
        member.setJoinedAt(LocalDateTime.now());

        ClassMember saved = classMemberRepository.save(member);
        log.info("✅ User {} joined class {} via invite code", user.getEmail(), clazz.getName());

        return new ClassMemberDTO(saved);
    }

    /**
     * ✅ Rời khỏi lớp (bởi chính student)
     */
    @Transactional
    public void leaveClass(Long classId, Long userId) {
        // Kiểm tra lớp tồn tại
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // Không cho phép owner rời lớp
        if (userId.equals(clazz.getOwnerId())) {
            throw new RuntimeException("Giáo viên chủ nhiệm không thể rời khỏi lớp");
        }

        // ✅ FIXED: Delete using composite ID
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        if (!classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn không phải thành viên của lớp này");
        }

        classMemberRepository.deleteById(memberId);
        log.info("✅ User {} left class {}", userId, clazz.getName());
    }

    /**
     * ✅ Lấy danh sách members của lớp
     */
    public List<ClassMemberDTO> getClassMembers(Long classId, Long requesterId) {
        // Kiểm tra lớp tồn tại
        Class clazz = classRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy lớp học"));

        // ✅ FIXED: Check membership using composite ID
        ClassMemberId memberId = new ClassMemberId(classId, requesterId);
        if (!clazz.isOwnedBy(requesterId) && !classMemberRepository.existsById(memberId)) {
            throw new RuntimeException("Bạn không có quyền xem danh sách thành viên");
        }

        // ✅ FIXED: Use correct repository method
        List<ClassMember> members = classMemberRepository.findByIdClassId(classId);
        return members.stream()
                .map(ClassMemberDTO::new)
                .collect(Collectors.toList());
    }

    /**
     * ✅ Lấy danh sách lớp mà user tham gia
     */
    public List<Long> getClassIdsByUser(Long userId) {
        // ✅ FIXED: Use correct repository method
        List<ClassMember> members = classMemberRepository.findByIdUserId(userId);
        return members.stream()
                .map(member -> member.getId().getClassId())
                .collect(Collectors.toList());
    }

    /**
     * ✅ Kiểm tra user có phải member của lớp không
     */
    public boolean isMember(Long classId, Long userId) {
        ClassMemberId memberId = new ClassMemberId(classId, userId);
        return classMemberRepository.existsById(memberId);
    }

    /**
     * ✅ Đếm số members trong lớp
     */
    public long countMembers(Long classId) {
        return classMemberRepository.countByIdClassId(classId);
    }
}