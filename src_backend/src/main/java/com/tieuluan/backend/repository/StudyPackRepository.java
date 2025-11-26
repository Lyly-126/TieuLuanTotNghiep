package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.StudyPack;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StudyPackRepository extends JpaRepository<StudyPack, Long> {

    List<StudyPack> findByDeletedAtIsNull();
    
    List<StudyPack> findByTargetRoleAndDeletedAtIsNull(StudyPack.TargetRole targetRole);
}