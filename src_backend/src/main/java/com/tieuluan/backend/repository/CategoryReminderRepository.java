package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.CategoryReminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository cho CategoryReminder
 * ✅ Sử dụng Long cho userId và categoryId
 */
@Repository
public interface CategoryReminderRepository extends JpaRepository<CategoryReminder, Long> {

    /**
     * Lấy reminder của 1 category cho user
     */
    Optional<CategoryReminder> findByUserIdAndCategoryId(Long userId, Long categoryId);

    /**
     * Lấy tất cả reminders của user
     */
    List<CategoryReminder> findByUserId(Long userId);

    /**
     * Lấy tất cả reminders đang bật của user
     */
    List<CategoryReminder> findByUserIdAndIsEnabledTrue(Long userId);

    /**
     * Lấy reminders cần gửi notification tại thời điểm cụ thể
     */
    @Query("SELECT cr FROM CategoryReminder cr WHERE cr.isEnabled = true " +
            "AND cr.reminderTime = :time " +
            "AND SUBSTRING(cr.daysOfWeek, :dayOfWeek + 1, 1) = '1'")
    List<CategoryReminder> findRemindersToSend(
            @Param("time") LocalTime time,
            @Param("dayOfWeek") int dayOfWeek
    );

    /**
     * Lấy reminders có FCM token
     */
    @Query("SELECT cr FROM CategoryReminder cr WHERE cr.isEnabled = true " +
            "AND cr.fcmToken IS NOT NULL AND cr.fcmToken <> ''")
    List<CategoryReminder> findActiveRemindersWithFcmToken();

    /**
     * Xóa reminder của category
     */
    void deleteByUserIdAndCategoryId(Long userId, Long categoryId);

    /**
     * Đếm số reminders đang bật của user
     */
    long countByUserIdAndIsEnabledTrue(Long userId);

    /**
     * Kiểm tra tồn tại
     */
    boolean existsByUserIdAndCategoryId(Long userId, Long categoryId);

    /**
     * Xóa tất cả reminders của user
     */
    void deleteByUserId(Long userId);

    /**
     * Xóa tất cả reminders của category (khi category bị xóa)
     */
    void deleteByCategoryId(Long categoryId);
}