package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.ClassMember;
import com.tieuluan.backend.model.ClassMemberId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClassMemberRepository extends JpaRepository<ClassMember, ClassMemberId> {

    // ✅ Query by embedded ID fields
    List<ClassMember> findByIdClassId(Long classId);
    List<ClassMember> findByIdUserId(Long userId);

    // ✅ Count by embedded ID field
    long countByIdClassId(Long classId);

}