package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.PolicyDTO;
import com.tieuluan.backend.service.PolicyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/policies")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PolicyController {

    private final PolicyService policyService;

    // ================== PUBLIC/USER ENDPOINTS ==================

    /**
     * GET /api/policies - Lấy tất cả policies ACTIVE (public)
     */
    @GetMapping
    public ResponseEntity<List<PolicyDTO>> getActivePolicies() {
        try {
            List<PolicyDTO> policies = policyService.getActivePolicies();
            return ResponseEntity.ok(policies);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/policies/{id} - Lấy một policy theo ID (public, chỉ ACTIVE)
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getActivePolicyById(@PathVariable Long id) {
        try {
            PolicyDTO policy = policyService.getActivePolicyById(id);
            return ResponseEntity.ok(policy);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Lỗi server"));
        }
    }

    // ================== ADMIN ENDPOINTS ==================

    /**
     * GET /api/policies/admin/all - Admin lấy tất cả policies (bất kể status)
     */
    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<PolicyDTO>> getAllPolicies() {
        try {
            List<PolicyDTO> policies = policyService.getAllPolicies();
            return ResponseEntity.ok(policies);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/policies/admin/{id} - Admin lấy một policy (bất kể status)
     */
    @GetMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> getPolicyById(@PathVariable Long id) {
        try {
            PolicyDTO policy = policyService.getPolicyById(id);
            return ResponseEntity.ok(policy);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Lỗi server"));
        }
    }

    /**
     * POST /api/policies/admin - Admin tạo policy mới
     */
    @PostMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createPolicy(@RequestBody PolicyDTO.CreateRequest request) {
        try {
            PolicyDTO policy = policyService.createPolicy(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(policy);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Lỗi server"));
        }
    }

    /**
     * PUT /api/policies/admin/{id} - Admin cập nhật policy
     */
    @PutMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updatePolicy(
            @PathVariable Long id,
            @RequestBody PolicyDTO.UpdateRequest request
    ) {
        try {
            PolicyDTO policy = policyService.updatePolicy(id, request);
            return ResponseEntity.ok(policy);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Lỗi server"));
        }
    }

    /**
     * DELETE /api/policies/admin/{id} - Admin xóa policy
     */
    @DeleteMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deletePolicy(@PathVariable Long id) {
        try {
            policyService.deletePolicy(id);
            return ResponseEntity.ok(Map.of("message", "Xóa điều khoản thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Lỗi server"));
        }
    }

    /**
     * PATCH /api/policies/admin/{id}/status - Admin thay đổi status
     */
    @PatchMapping("/admin/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> changeStatus(
            @PathVariable Long id,
            @RequestParam String status
    ) {
        try {
            PolicyDTO policy = policyService.changeStatus(id, status);
            return ResponseEntity.ok(policy);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Lỗi server"));
        }
    }
}