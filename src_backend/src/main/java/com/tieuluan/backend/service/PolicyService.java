package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.PolicyDTO;
import com.tieuluan.backend.model.Policy;
import com.tieuluan.backend.repository.PolicyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PolicyService {

    private final PolicyRepository policyRepository;

    // ================== USER METHODS ==================

    /**
     * Lấy tất cả policies có status = ACTIVE (cho user xem)
     */
    public List<PolicyDTO> getActivePolicies() {
        return policyRepository.findByStatusOrderByUpdatedAtDesc(Policy.PolicyStatus.ACTIVE)
                .stream()
                .map(PolicyDTO::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Lấy một policy theo ID (chỉ nếu ACTIVE)
     */
    public PolicyDTO getActivePolicyById(Long id) {
        Policy policy = policyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy điều khoản"));

        // Chỉ cho phép xem nếu status = ACTIVE
        if (policy.getStatus() != Policy.PolicyStatus.ACTIVE) {
            throw new RuntimeException("Điều khoản này không khả dụng");
        }

        return PolicyDTO.fromEntity(policy);
    }

    // ================== ADMIN METHODS ==================

    /**
     * Admin: Lấy tất cả policies (bất kể status)
     */
    public List<PolicyDTO> getAllPolicies() {
        return policyRepository.findAllByOrderByUpdatedAtDesc()
                .stream()
                .map(PolicyDTO::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Admin: Lấy một policy theo ID (bất kể status)
     */
    public PolicyDTO getPolicyById(Long id) {
        Policy policy = policyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy điều khoản"));
        return PolicyDTO.fromEntity(policy);
    }

    /**
     * Admin: Tạo policy mới
     */
    @Transactional
    public PolicyDTO createPolicy(PolicyDTO.CreateRequest request) {
        // Validate
        if (request.getTitle() == null || request.getTitle().trim().isEmpty()) {
            throw new RuntimeException("Tiêu đề không được để trống");
        }
        if (request.getBody() == null || request.getBody().trim().isEmpty()) {
            throw new RuntimeException("Nội dung không được để trống");
        }

        Policy policy = new Policy();
        policy.setTitle(request.getTitle().trim());
        policy.setBody(request.getBody().trim());

        // Set status
        if (request.getStatus() != null) {
            try {
                policy.setStatus(Policy.PolicyStatus.valueOf(request.getStatus()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Status không hợp lệ. Chỉ chấp nhận: ACTIVE, INACTIVE, DRAFT");
            }
        } else {
            policy.setStatus(Policy.PolicyStatus.ACTIVE);
        }

        Policy savedPolicy = policyRepository.save(policy);
        return PolicyDTO.fromEntity(savedPolicy);
    }

    /**
     * Admin: Cập nhật policy
     */
    @Transactional
    public PolicyDTO updatePolicy(Long id, PolicyDTO.UpdateRequest request) {
        Policy policy = policyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy điều khoản"));

        // Update title
        if (request.getTitle() != null && !request.getTitle().trim().isEmpty()) {
            policy.setTitle(request.getTitle().trim());
        }

        // Update body
        if (request.getBody() != null && !request.getBody().trim().isEmpty()) {
            policy.setBody(request.getBody().trim());
        }

        // Update status
        if (request.getStatus() != null) {
            try {
                policy.setStatus(Policy.PolicyStatus.valueOf(request.getStatus()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Status không hợp lệ. Chỉ chấp nhận: ACTIVE, INACTIVE, DRAFT");
            }
        }

        Policy updatedPolicy = policyRepository.save(policy);
        return PolicyDTO.fromEntity(updatedPolicy);
    }

    /**
     * Admin: Xóa policy
     */
    @Transactional
    public void deletePolicy(Long id) {
        if (!policyRepository.existsById(id)) {
            throw new RuntimeException("Không tìm thấy điều khoản");
        }
        policyRepository.deleteById(id);
    }

    /**
     * Admin: Thay đổi status của policy
     */
    @Transactional
    public PolicyDTO changeStatus(Long id, String status) {
        Policy policy = policyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy điều khoản"));

        try {
            policy.setStatus(Policy.PolicyStatus.valueOf(status));
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Status không hợp lệ. Chỉ chấp nhận: ACTIVE, INACTIVE, DRAFT");
        }

        Policy updatedPolicy = policyRepository.save(policy);
        return PolicyDTO.fromEntity(updatedPolicy);
    }
}