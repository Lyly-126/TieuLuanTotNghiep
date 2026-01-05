package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.StudyReminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface StudyReminderRepository extends JpaRepository<StudyReminder, Integer> {

    /**
     * Lấy reminder settings của user
     */
    Optional<StudyReminder> findByUserId(Integer userId);

    /**
     * Lấy tất cả reminders đang bật
     */
    List<StudyReminder> findByIsEnabledTrue();

    /**
     * Lấy reminders cần gửi vào thời điểm cụ thể
     * @param time Thời gian cần kiểm tra
     * @param dayOfWeek Ngày trong tuần (0-6)
     */
    @Query("SELECT sr FROM StudyReminder sr WHERE sr.isEnabled = true AND sr.reminderTime = :time AND SUBSTRING(sr.daysOfWeek, :dayOfWeek + 1, 1) = '1'")
    List<StudyReminder> findRemindersToSend(@Param("time") LocalTime time, @Param("dayOfWeek") int dayOfWeek);

    /**
     * Lấy reminders có FCM token (cho push notification)
     */
    @Query("SELECT sr FROM StudyReminder sr WHERE sr.isEnabled = true AND sr.fcmToken IS NOT NULL AND sr.fcmToken <> ''")
    List<StudyReminder> findActiveRemindersWithFcmToken();

    /**
     * Xóa reminder của user
     */
    void deleteByUserId(Integer userId);
}