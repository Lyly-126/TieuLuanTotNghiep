package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.StudyPackDTO;
import com.tieuluan.backend.model.StudyPack;
import com.tieuluan.backend.repository.StudyPackRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudyPackService {

    private final StudyPackRepository studyPackRepository;

    /**
     * Lấy tất cả study packs (public)
     */
    public List<StudyPackDTO> getAllPacks() {
        return studyPackRepository.findAll().stream()
                .filter(pack -> pack.getDeletedAt() == null)
                .map(StudyPackDTO::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Lấy study pack theo ID
     */
    public StudyPackDTO getPackById(Long id) {
        StudyPack pack = studyPackRepository.findById(id)
                .filter(p -> p.getDeletedAt() == null)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));
        return StudyPackDTO.fromEntity(pack);
    }

    /**
     * Admin: Tạo study pack mới
     */
    @Transactional
    public StudyPackDTO createPack(StudyPackDTO.CreateRequest request) {
        if (request.getName() == null || request.getName().trim().isEmpty()) {
            throw new RuntimeException("Tên gói không được để trống");
        }

        if (request.getPrice() == null || request.getPrice().compareTo(java.math.BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Giá không hợp lệ");
        }

        if (request.getDurationDays() == null || request.getDurationDays() <= 0) {
            throw new RuntimeException("Thời hạn không hợp lệ");
        }

        StudyPack pack = new StudyPack();
        pack.setName(request.getName());
        pack.setDescription(request.getDescription());
        pack.setPrice(request.getPrice());
        pack.setDurationDays(request.getDurationDays());

        // ✅ THÊM: Set targetRole
        if (request.getTargetRole() != null) {
            try {
                StudyPack.TargetRole targetRole = StudyPack.TargetRole.valueOf(request.getTargetRole());
                pack.setTargetRole(targetRole);
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Target role không hợp lệ. Chỉ chấp nhận: NORMAL_USER hoặc TEACHER");
            }
        } else {
            // Default là NORMAL_USER
            pack.setTargetRole(StudyPack.TargetRole.NORMAL_USER);
        }

        StudyPack saved = studyPackRepository.save(pack);
        return StudyPackDTO.fromEntity(saved);
    }

    /**
     * Admin: Cập nhật study pack
     */
    @Transactional
    public StudyPackDTO updatePack(Long id, StudyPackDTO.UpdateRequest request) {
        StudyPack pack = studyPackRepository.findById(id)
                .filter(p -> p.getDeletedAt() == null)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));

        if (request.getName() != null && !request.getName().trim().isEmpty()) {
            pack.setName(request.getName());
        }

        if (request.getDescription() != null) {
            pack.setDescription(request.getDescription());
        }

        if (request.getPrice() != null) {
            if (request.getPrice().compareTo(java.math.BigDecimal.ZERO) < 0) {
                throw new RuntimeException("Giá không hợp lệ");
            }
            pack.setPrice(request.getPrice());
        }

        if (request.getDurationDays() != null) {
            if (request.getDurationDays() <= 0) {
                throw new RuntimeException("Thời hạn không hợp lệ");
            }
            pack.setDurationDays(request.getDurationDays());
        }

        // ✅ THÊM: Update targetRole
        if (request.getTargetRole() != null) {
            try {
                StudyPack.TargetRole targetRole = StudyPack.TargetRole.valueOf(request.getTargetRole());
                pack.setTargetRole(targetRole);
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Target role không hợp lệ. Chỉ chấp nhận: NORMAL_USER hoặc TEACHER");
            }
        }

        StudyPack updated = studyPackRepository.save(pack);
        return StudyPackDTO.fromEntity(updated);
    }

    /**
     * Admin: Xóa study pack (soft delete)
     */
    @Transactional
    public void deletePack(Long id) {
        StudyPack pack = studyPackRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói học tập"));

        pack.setDeletedAt(java.time.ZonedDateTime.now());
        studyPackRepository.save(pack);
    }

    /**
     * ✅ THÊM: Lấy gói theo targetRole
     */
    public List<StudyPackDTO> getPacksByTargetRole(String targetRole) {
        try {
            StudyPack.TargetRole role = StudyPack.TargetRole.valueOf(targetRole);
            return studyPackRepository.findAll().stream()
                    .filter(pack -> pack.getDeletedAt() == null && pack.getTargetRole() == role)
                    .map(StudyPackDTO::fromEntity)
                    .collect(Collectors.toList());
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Target role không hợp lệ");
        }
    }
}