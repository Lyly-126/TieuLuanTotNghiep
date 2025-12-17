package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.StudyPackDTO;
import com.tieuluan.backend.service.StudyPackService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/study-packs")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StudyPackController {

    private final StudyPackService studyPackService;

    // ==================== PUBLIC ENDPOINTS ====================

    /**
     * Lấy tất cả gói học tập (public - không cần auth)
     */
    @GetMapping
    public ResponseEntity<List<StudyPackDTO>> getAllPacks() {
        try {
            log.info("📋 Fetching all study packs");  // ← THÊM
            List<StudyPackDTO> packs = studyPackService.getAllPacks();
            log.info("✅ Found {} packs", packs.size());  // ← THÊM
            return ResponseEntity.ok(packs);
        } catch (Exception e) {
            log.error("❌ Error: ", e);  // ← THÊM - QUAN TRỌNG!
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Lấy chi tiết gói theo ID (public)
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getPackById(@PathVariable Long id) {
        try {
            StudyPackDTO pack = studyPackService.getPackById(id);
            return ResponseEntity.ok(pack);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== ADMIN ENDPOINTS ====================

    /**
     * Admin: Tạo gói học tập mới
     */
    @PostMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createPack(@RequestBody StudyPackDTO.CreateRequest request) {
        try {
            StudyPackDTO pack = studyPackService.createPack(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(pack);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Cập nhật gói học tập
     */
    @PutMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> updatePack(
            @PathVariable Long id,
            @RequestBody StudyPackDTO.UpdateRequest request
    ) {
        try {
            StudyPackDTO pack = studyPackService.updatePack(id, request);
            return ResponseEntity.ok(pack);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Xóa gói học tập
     */
    @DeleteMapping("/admin/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deletePack(@PathVariable Long id) {
        try {
            studyPackService.deletePack(id);
            return ResponseEntity.ok(Map.of("message", "Đã xóa gói học tập"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", e.getMessage()));
        }
    }
}