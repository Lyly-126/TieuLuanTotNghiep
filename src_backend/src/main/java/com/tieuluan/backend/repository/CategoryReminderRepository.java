package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.CategoryReminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryReminderRepository extends JpaRepository<CategoryReminder, Long> {

    Optional<CategoryReminder> findByUserIdAndCategoryId(Long userId, Long categoryId);

    List<CategoryReminder> findByUserId(Long userId);

    List<CategoryReminder> findByUserIdAndIsEnabledTrue(Long userId);

    // Lấy reminders cần gửi notification (có fcmToken)
    @Query("""
        SELECT cr FROM CategoryReminder cr 
        WHERE cr.isEnabled = true 
        AND cr.reminderTime = :time 
        AND SUBSTRING(cr.daysOfWeek, :dayOfWeek + 1, 1) = '1'
        AND cr.fcmToken IS NOT NULL 
        AND cr.fcmToken != ''
        """)
    List<CategoryReminder> findRemindersToSend(
            @Param("time") LocalTime time,
            @Param("dayOfWeek") int dayOfWeek
    );

    // Tìm reminders trùng giờ (cảnh báo xung đột)
    @Query("""
        SELECT cr FROM CategoryReminder cr 
        WHERE cr.userId = :userId 
        AND cr.reminderTime = :time 
        AND cr.isEnabled = true
        AND cr.categoryId != :excludeCategoryId
        """)
    List<CategoryReminder> findConflictingReminders(
            @Param("userId") Long userId,
            @Param("time") LocalTime time,
            @Param("excludeCategoryId") Long excludeCategoryId
    );

    @Modifying
    void deleteByUserIdAndCategoryId(Long userId, Long categoryId);

    // Cập nhật fcmToken cho tất cả reminders của user
    @Modifying
    @Query("UPDATE CategoryReminder cr SET cr.fcmToken = :fcmToken WHERE cr.userId = :userId")
    void updateFcmTokenByUserId(@Param("userId") Long userId, @Param("fcmToken") String fcmToken);

    // Xóa fcmToken của tất cả reminders của user (khi logout)
    @Modifying
    @Query("UPDATE CategoryReminder cr SET cr.fcmToken = NULL WHERE cr.userId = :userId")
    void clearFcmTokenByUserId(@Param("userId") Long userId);
}