package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Policy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PolicyRepository extends JpaRepository<Policy, Long> {

    // Tìm tất cả policies có status = ACTIVE (cho user xem)
    List<Policy> findByStatus(Policy.PolicyStatus status);

    // Tìm policies có status = ACTIVE, sắp xếp theo updatedAt giảm dần
    List<Policy> findByStatusOrderByUpdatedAtDesc(Policy.PolicyStatus status);

    // Admin có thể lấy tất cả bất kể status
    List<Policy> findAllByOrderByUpdatedAtDesc();
}