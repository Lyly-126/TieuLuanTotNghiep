// File: src/main/java/.../repository/ClassMemberRepository.java

package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.ClassMember;
import com.tieuluan.backend.model.ClassMemberId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClassMemberRepository extends JpaRepository<ClassMember, ClassMemberId> {

    // ✅ SỬA: Dùng @Query thay vì method name query
    @Query("SELECT cm FROM ClassMember cm WHERE cm.id.classId = :classId AND cm.status = :status")
    List<ClassMember> findByClassIdAndStatus(@Param("classId") Long classId, @Param("status") String status);

    // ✅ SỬA: Dùng id.classId vì classId là part của composite key
    @Query("SELECT cm FROM ClassMember cm WHERE cm.id.classId = :classId")
    List<ClassMember> findByIdClassId(@Param("classId") Long classId);

    // ✅ SỬA: userId cũng nằm trong composite key
    @Query("SELECT cm FROM ClassMember cm WHERE cm.id.userId = :userId")
    List<ClassMember> findByIdUserId(@Param("userId") Long userId);

    // ✅ THÊM: Count members của class
    @Query("SELECT COUNT(cm) FROM ClassMember cm WHERE cm.id.classId = :classId AND cm.status = 'APPROVED'")
    long countByIdClassIdAndStatusApproved(@Param("classId") Long classId);

    // ✅ THÊM: Check if user is member
    @Query("SELECT CASE WHEN COUNT(cm) > 0 THEN true ELSE false END FROM ClassMember cm WHERE cm.id.classId = :classId AND cm.id.userId = :userId")
    boolean existsByClassIdAndUserId(@Param("classId") Long classId, @Param("userId") Long userId);

    // ✅ THÊM: Get class IDs by user
    @Query("SELECT cm.id.classId FROM ClassMember cm WHERE cm.id.userId = :userId AND cm.status = 'APPROVED'")
    List<Long> findClassIdsByUserId(@Param("userId") Long userId);

    // ✅ Optional: Find specific member
    @Query("SELECT cm FROM ClassMember cm WHERE cm.id.classId = :classId AND cm.id.userId = :userId")
    Optional<ClassMember> findByClassIdAndUserId(@Param("classId") Long classId, @Param("userId") Long userId);
}