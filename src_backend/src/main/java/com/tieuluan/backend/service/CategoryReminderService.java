package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.CategoryReminderDTO;
import com.tieuluan.backend.dto.UpdateCategoryReminderRequest;
import com.tieuluan.backend.model.CategoryReminder;
import com.tieuluan.backend.repository.CategoryReminderRepository;
import com.tieuluan.backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service cho Category Reminder
 * ✅ Sử dụng Long cho userId và categoryId
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CategoryReminderService {

    private final CategoryReminderRepository reminderRepository;
    private final CategoryRepository categoryRepository;

    // ==================== GET ====================

    /**
     * Lấy reminder của 1 category
     */
    public CategoryReminderDTO getReminder(Long userId, Long categoryId) {
        CategoryReminder reminder = reminderRepository
                .findByUserIdAndCategoryId(userId, categoryId)
                .orElse(null);

        if (reminder == null) {
            // Trả về default settings (chưa bật)
            CategoryReminderDTO dto = new CategoryReminderDTO();
            dto.setCategoryId(categoryId);
            dto.setReminderTime(LocalTime.of(20, 0));
            dto.setDaysOfWeek("1111111");
            dto.setIsEnabled(false);

            // Lấy tên category
            categoryRepository.findById(categoryId).ifPresent(cat -> {
                dto.setCategoryName(cat.getName());
            });

            return dto;
        }

        return toDTO(reminder);
    }

    /**
     * Lấy tất cả reminders của user
     */
    public List<CategoryReminderDTO> getAllReminders(Long userId) {
        return reminderRepository.findByUserId(userId)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    /**
     * Lấy reminders đang bật của user
     */
    public List<CategoryReminderDTO> getActiveReminders(Long userId) {
        return reminderRepository.findByUserIdAndIsEnabledTrue(userId)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    /**
     * Đếm số reminders đang bật
     */
    public long countActiveReminders(Long userId) {
        return reminderRepository.countByUserIdAndIsEnabledTrue(userId);
    }

    // ==================== UPDATE ====================

    /**
     * Cập nhật reminder cho category
     */
    @Transactional
    public CategoryReminderDTO updateReminder(
            Long userId,
            Long categoryId,
            UpdateCategoryReminderRequest request) {

        // Tìm hoặc tạo mới
        CategoryReminder reminder = reminderRepository
                .findByUserIdAndCategoryId(userId, categoryId)
                .orElseGet(() -> new CategoryReminder(userId, categoryId));

        // Cập nhật các trường
        if (request.getHour() != null && request.getMinute() != null) {
            reminder.setReminderTime(LocalTime.of(request.getHour(), request.getMinute()));
        }

        if (request.getDaysOfWeek() != null) {
            reminder.setDaysOfWeek(request.getDaysOfWeek());
        }

        if (request.getIsEnabled() != null) {
            reminder.setIsEnabled(request.getIsEnabled());
        }

        if (request.getCustomMessage() != null) {
            reminder.setCustomMessage(request.getCustomMessage());
        }

        if (request.getFcmToken() != null) {
            reminder.setFcmToken(request.getFcmToken());
        }

        reminder.setUpdatedAt(LocalDateTime.now());
        reminderRepository.save(reminder);

        log.info("✅ Updated category reminder: userId={}, categoryId={}, enabled={}",
                userId, categoryId, reminder.getIsEnabled());

        return toDTO(reminder);
    }

    /**
     * Bật/tắt reminder nhanh
     */
    @Transactional
    public CategoryReminderDTO toggleReminder(Long userId, Long categoryId, boolean enabled) {
        CategoryReminder reminder = reminderRepository
                .findByUserIdAndCategoryId(userId, categoryId)
                .orElseGet(() -> {
                    CategoryReminder newReminder = new CategoryReminder(userId, categoryId);
                    return reminderRepository.save(newReminder);
                });

        reminder.setIsEnabled(enabled);
        reminder.setUpdatedAt(LocalDateTime.now());
        reminderRepository.save(reminder);

        log.info("✅ Toggled category reminder: userId={}, categoryId={}, enabled={}",
                userId, categoryId, enabled);

        return toDTO(reminder);
    }

    // ==================== DELETE ====================

    /**
     * Xóa reminder của category
     */
    @Transactional
    public void deleteReminder(Long userId, Long categoryId) {
        reminderRepository.deleteByUserIdAndCategoryId(userId, categoryId);
        log.info("✅ Deleted category reminder: userId={}, categoryId={}", userId, categoryId);
    }

    // ==================== NOTIFICATION ====================

    /**
     * Lấy reminders cần gửi notification tại thời điểm hiện tại
     */
    public List<CategoryReminder> getRemindersToSendNow() {
        LocalTime now = LocalTime.now().withSecond(0).withNano(0);
        int dayOfWeek = LocalDate.now().getDayOfWeek().getValue() % 7; // 0=CN, 1=T2, ...

        return reminderRepository.findRemindersToSend(now, dayOfWeek);
    }

    // ==================== HELPER ====================

    /**
     * Convert Entity to DTO
     */
    private CategoryReminderDTO toDTO(CategoryReminder reminder) {
        CategoryReminderDTO dto = new CategoryReminderDTO();
        dto.setId(reminder.getId());
        dto.setCategoryId(reminder.getCategoryId());
        dto.setReminderTime(reminder.getReminderTime());
        dto.setDaysOfWeek(reminder.getDaysOfWeek());
        dto.setEnabledDays(reminder.getEnabledDaysVietnamese());
        dto.setIsEnabled(reminder.getIsEnabled());
        dto.setCustomMessage(reminder.getCustomMessage());

        // Lấy tên category
        categoryRepository.findById(reminder.getCategoryId()).ifPresent(cat -> {
            dto.setCategoryName(cat.getName());
        });

        return dto;
    }
}