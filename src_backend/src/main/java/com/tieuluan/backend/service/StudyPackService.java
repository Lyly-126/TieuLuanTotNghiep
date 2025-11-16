package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.StudyPackDTO;
import com.tieuluan.backend.model.StudyPack;
import com.tieuluan.backend.repository.StudyPackRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.ZonedDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudyPackService {

    private final StudyPackRepository studyPackRepository;

    // ==================== PUBLIC METHODS ====================

    /**
     * Lấy tất cả gói học tập (không bao gồm đã xóa)
     */
    public List<StudyPackDTO> getAllPacks() {
        return studyPackRepository.findByDeletedAtIsNull()
                .stream()
                .map(StudyPackDTO::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Lấy gói theo ID
     */
    public StudyPackDTO getPackById(Long id) {
        StudyPack pack = studyPackRepository.findById(id)
                .filter(p -> p.getDeletedAt() == null)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));
        return StudyPackDTO.fromEntity(pack);
    }

    // ==================== ADMIN METHODS ====================

    /**
     * Admin: Tạo gói mới
     */
    @Transactional
    public StudyPackDTO createPack(StudyPackDTO.CreateRequest request) {
        // Validate
        if (request.getName() == null || request.getName().trim().isEmpty()) {
            throw new RuntimeException("Tên gói không được để trống");
        }
        if (request.getPrice() == null || request.getPrice().compareTo(java.math.BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Giá không hợp lệ");
        }
        if (request.getDurationDays() == null || request.getDurationDays() <= 0) {
            throw new RuntimeException("durationDays phải > 0");
        }

        StudyPack pack = new StudyPack();
        pack.setName(request.getName().trim());
        pack.setDescription(request.getDescription());
        pack.setPrice(request.getPrice());
        pack.setDurationDays(request.getDurationDays());


        StudyPack savedPack = studyPackRepository.save(pack);
        return StudyPackDTO.fromEntity(savedPack);
    }

    /**
     * Admin: Cập nhật gói
     */
    @Transactional
    public StudyPackDTO updatePack(Long id, StudyPackDTO.UpdateRequest request) {
        StudyPack pack = studyPackRepository.findById(id)
                .filter(p -> p.getDeletedAt() == null)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));

        // Validate
        if (request.getName() == null || request.getName().trim().isEmpty()) {
            throw new RuntimeException("Tên gói không được để trống");
        }
        if (request.getPrice() == null || request.getPrice().compareTo(java.math.BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Giá không hợp lệ");
        }
        if (request.getDurationDays() == null || request.getDurationDays() <= 0) {
            throw new RuntimeException("durationDays phải > 0");
        }

        pack.setName(request.getName().trim());
        pack.setDescription(request.getDescription());
        pack.setPrice(request.getPrice());
        pack.setUpdatedAt(ZonedDateTime.now());
        pack.setDurationDays(request.getDurationDays());

        StudyPack updatedPack = studyPackRepository.save(pack);
        return StudyPackDTO.fromEntity(updatedPack);
    }

    /**
     * Admin: Xóa mềm gói (soft delete)
     */
    @Transactional
    public void deletePack(Long id) {
        StudyPack pack = studyPackRepository.findById(id)
                .filter(p -> p.getDeletedAt() == null)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));

        // Soft delete - chỉ set deletedAt
        pack.setDeletedAt(ZonedDateTime.now());
        studyPackRepository.save(pack);
    }
}



