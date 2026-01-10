package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.CategoryReminderDTO;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.CategoryReminder;
import com.tieuluan.backend.repository.CategoryReminderRepository;
import com.tieuluan.backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoryReminderService {

    private final CategoryReminderRepository reminderRepository;
    private final CategoryRepository categoryRepository;

    /**
     * Lấy tất cả reminders của user (cho thời khóa biểu)
     */
    public List<CategoryReminderDTO> getUserReminders(Long userId) {
        List<CategoryReminder> reminders = reminderRepository.findByUserIdAndIsEnabledTrue(userId);

        return reminders.stream()
                .map(r -> {
                    Category cat = categoryRepository.findById(r.getCategoryId()).orElse(null);
                    String name = cat != null ? cat.getName() : "Unknown";
                    return CategoryReminderDTO.fromEntity(r, name);
                })
                .sorted(Comparator.comparing(CategoryReminderDTO::getReminderTime))
                .collect(Collectors.toList());
    }

    /**
     * Lấy reminder của category cụ thể
     */
    public CategoryReminderDTO getCategoryReminder(Long userId, Long categoryId) {
        Category category = categoryRepository.findById(categoryId).orElse(null);
        String categoryName = category != null ? category.getName() : "Unknown";

        Optional<CategoryReminder> reminderOpt = reminderRepository.findByUserIdAndCategoryId(userId, categoryId);

        if (reminderOpt.isEmpty()) {
            return CategoryReminderDTO.defaultSettings(userId, categoryId, categoryName);
        }

        CategoryReminderDTO dto = CategoryReminderDTO.fromEntity(reminderOpt.get(), categoryName);

        // Check conflicts
        addConflictInfo(dto, userId, reminderOpt.get().getReminderTime(), categoryId);

        return dto;
    }

    /**
     * Tạo hoặc cập nhật reminder (bao gồm fcmToken)
     */
    @Transactional
    public CategoryReminderDTO upsertReminder(
            Long userId,
            Long categoryId,
            Integer hour,
            Integer minute,
            String daysOfWeek,
            Boolean isEnabled,
            String customMessage,
            String fcmToken
    ) {
        CategoryReminder reminder = reminderRepository.findByUserIdAndCategoryId(userId, categoryId)
                .orElse(new CategoryReminder(userId, categoryId));

        if (hour != null && minute != null) {
            reminder.setReminderTime(LocalTime.of(hour, minute));
        }
        if (daysOfWeek != null && daysOfWeek.length() == 7) {
            reminder.setDaysOfWeek(daysOfWeek);
        }
        if (isEnabled != null) {
            reminder.setIsEnabled(isEnabled);
        }
        if (customMessage != null) {
            reminder.setCustomMessage(customMessage);
        }
        if (fcmToken != null && !fcmToken.isEmpty()) {
            reminder.setFcmToken(fcmToken);
        }

        reminder.setUpdatedAt(java.time.LocalDateTime.now());
        reminderRepository.save(reminder);

        log.info("✅ Upserted reminder for user {} category {}", userId, categoryId);
        return getCategoryReminder(userId, categoryId);
    }

    /**
     * Bật/tắt reminder (kèm fcmToken)
     */
    @Transactional
    public CategoryReminderDTO toggleReminder(Long userId, Long categoryId, Boolean enabled, String fcmToken) {
        CategoryReminder reminder = reminderRepository.findByUserIdAndCategoryId(userId, categoryId)
                .orElse(new CategoryReminder(userId, categoryId));

        reminder.setIsEnabled(enabled);
        if (fcmToken != null && !fcmToken.isEmpty()) {
            reminder.setFcmToken(fcmToken);
        }
        reminder.setUpdatedAt(java.time.LocalDateTime.now());
        reminderRepository.save(reminder);

        return getCategoryReminder(userId, categoryId);
    }

    /**
     * Xóa reminder
     */
    @Transactional
    public void deleteReminder(Long userId, Long categoryId) {
        reminderRepository.deleteByUserIdAndCategoryId(userId, categoryId);
    }

    /**
     * Cập nhật fcmToken cho tất cả reminders của user
     */
    @Transactional
    public void updateFcmToken(Long userId, String fcmToken) {
        reminderRepository.updateFcmTokenByUserId(userId, fcmToken);
        log.info("✅ Updated FCM token for user {}", userId);
    }

    /**
     * Xóa fcmToken của user (khi logout)
     */
    @Transactional
    public void clearFcmToken(Long userId) {
        reminderRepository.clearFcmTokenByUserId(userId);
        log.info("✅ Cleared FCM token for user {}", userId);
    }

    /**
     * Lấy reminders cần gửi notification ngay bây giờ
     */
    public List<CategoryReminder> getRemindersToSendNow() {
        LocalTime now = LocalTime.now().withSecond(0).withNano(0);
        int dayOfWeek = LocalDate.now().getDayOfWeek().getValue() % 7; // 0=CN, 1=T2...
        return reminderRepository.findRemindersToSend(now, dayOfWeek);
    }

    /**
     * Lấy thời khóa biểu tuần (grouped by day)
     */
    public Map<Integer, List<CategoryReminderDTO>> getWeeklySchedule(Long userId) {
        List<CategoryReminder> reminders = reminderRepository.findByUserIdAndIsEnabledTrue(userId);

        Map<Integer, List<CategoryReminderDTO>> schedule = new LinkedHashMap<>();
        for (int i = 0; i < 7; i++) {
            schedule.put(i, new ArrayList<>());
        }

        for (CategoryReminder r : reminders) {
            Category cat = categoryRepository.findById(r.getCategoryId()).orElse(null);
            String name = cat != null ? cat.getName() : "Unknown";
            CategoryReminderDTO dto = CategoryReminderDTO.fromEntity(r, name);

            for (int day = 0; day < 7; day++) {
                if (r.isDayEnabled(day)) {
                    schedule.get(day).add(dto);
                }
            }
        }

        schedule.values().forEach(list ->
                list.sort(Comparator.comparing(CategoryReminderDTO::getReminderTime)));

        return schedule;
    }

    /**
     * ✅ FIX: Check conflict phải trùng cả GIỜ và ÍT NHẤT 1 NGÀY
     */
    private void addConflictInfo(CategoryReminderDTO dto, Long userId, LocalTime time, Long excludeCategoryId) {
        // Lấy reminder hiện tại để có daysOfWeek
        CategoryReminder currentReminder = reminderRepository.findByUserIdAndCategoryId(userId, excludeCategoryId)
                .orElse(null);

        if (currentReminder == null || currentReminder.getDaysOfWeek() == null) {
            return;
        }

        String currentDays = currentReminder.getDaysOfWeek();

        // Lấy các reminders cùng giờ
        List<CategoryReminder> sameTimeReminders = reminderRepository.findConflictingReminders(userId, time, excludeCategoryId);

        // ✅ Filter: chỉ giữ những cái có ít nhất 1 ngày trùng
        List<CategoryReminder> actualConflicts = sameTimeReminders.stream()
                .filter(r -> hasOverlappingDays(currentDays, r.getDaysOfWeek()))
                .collect(Collectors.toList());

        if (!actualConflicts.isEmpty()) {
            dto.setHasConflict(true);
            dto.setConflicts(actualConflicts.stream()
                    .map(c -> {
                        Category cat = categoryRepository.findById(c.getCategoryId()).orElse(null);
                        return new CategoryReminderDTO.ConflictInfo(
                                c.getCategoryId(),
                                cat != null ? cat.getName() : "Unknown",
                                c.getTimeDisplay()
                        );
                    })
                    .collect(Collectors.toList()));
        } else {
            dto.setHasConflict(false);
            dto.setConflicts(Collections.emptyList());
        }
    }

    /**
     * ✅ Check xem 2 daysOfWeek có ít nhất 1 ngày trùng nhau không
     * Format: "1111111" (index 0=CN, 1=T2, ..., 6=T7)
     * Ví dụ: "1100000" và "0011111" → false (không trùng ngày nào)
     *        "1100000" và "0100000" → true (trùng T2)
     */
    private boolean hasOverlappingDays(String days1, String days2) {
        if (days1 == null || days2 == null) return false;
        if (days1.length() != 7 || days2.length() != 7) return false;

        for (int i = 0; i < 7; i++) {
            // Nếu cả 2 đều = '1' tại vị trí i → có ngày trùng
            if (days1.charAt(i) == '1' && days2.charAt(i) == '1') {
                return true;
            }
        }
        return false;
    }
}