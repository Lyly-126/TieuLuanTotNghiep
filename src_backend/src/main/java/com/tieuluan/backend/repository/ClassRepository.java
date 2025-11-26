package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Class;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ClassRepository extends JpaRepository<Class, Long> {

    // Lấy tất cả lớp của teacher
    List<Class> findByOwnerId(Long ownerId);

    // Kiểm tra teacher có sở hữu lớp không
    boolean existsByIdAndOwnerId(Long id, Long ownerId);

    // Tìm lớp theo tên (cho search)
    List<Class> findByNameContainingIgnoreCase(String keyword);

    // Lấy lớp với owner info (eager fetch)
    Optional<Class> findByIdAndOwnerId(Long id, Long ownerId);
}