package com.tieuluan.backend.service;

import com.tieuluan.backend.dto.*;
import com.tieuluan.backend.model.*;
import com.tieuluan.backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class StudyProgressService {

    @Autowired
    private StudyProgressRepository progressRepository;

    @Autowired
    private StudyStreakRepository streakRepository;



    @Autowired
    private DailyStudyLogRepository dailyLogRepository;

    @Autowired
    private FlashcardRepository flashcardRepository;

    // ==================== PROGRESS ====================

    /**
     * Lấy tiến trình học của user cho một category
     */
    public CategoryProgressDTO getCategoryProgress(Integer userId, Integer categoryId) {
        // Đếm tổng số thẻ trong category
        Long totalCardsLong = flashcardRepository.countByCategoryId(Long.valueOf(categoryId));
        Integer totalCards = totalCardsLong != null ? totalCardsLong.intValue() : 0;

        CategoryProgressDTO dto = new CategoryProgressDTO();
        dto.setCategoryId(categoryId);
        dto.setTotalCards(totalCards);

        if (totalCards == 0) {
            dto.calculateStats();
            return dto;
        }

        // Lấy số liệu từ progress
        Integer masteredCount = progressRepository.countMasteredCards(userId, categoryId);
        Integer learningCount = progressRepository.countLearningCards(userId, categoryId);
        Integer correctSum = progressRepository.sumCorrectCount(userId, categoryId);
        Integer incorrectSum = progressRepository.sumIncorrectCount(userId, categoryId);

        dto.setMasteredCards(masteredCount != null ? masteredCount : 0);
        dto.setLearningCards(learningCount != null ? learningCount : 0);
        dto.setCorrectCount(correctSum != null ? correctSum : 0);
        dto.setIncorrectCount(incorrectSum != null ? incorrectSum : 0);

        // Lấy lần học cuối
        List<StudyProgress> progressList = progressRepository.findByUserIdAndCategoryId(userId, categoryId);
        if (!progressList.isEmpty()) {
            LocalDateTime lastStudied = progressList.stream()
                    .map(StudyProgress::getLastStudiedAt)
                    .filter(d -> d != null)
                    .max(LocalDateTime::compareTo)
                    .orElse(null);
            dto.setLastStudiedAt(lastStudied);
        }

        dto.calculateStats();
        return dto;
    }

    /**
     * Cập nhật tiến trình sau khi user trả lời
     */
    @Transactional
    public StudyProgress updateProgress(Integer userId, Integer flashcardId, Integer categoryId, boolean isCorrect) {
        // Tìm hoặc tạo mới progress
        StudyProgress progress = progressRepository.findByUserIdAndFlashcardId(userId, flashcardId)
                .orElseGet(() -> {
                    StudyProgress newProgress = new StudyProgress(userId, flashcardId, categoryId);
                    return progressRepository.save(newProgress);
                });

        // Cập nhật kết quả
        if (isCorrect) {
            progress.recordCorrect();
        } else {
            progress.recordIncorrect();
        }

        progressRepository.save(progress);

        // Cập nhật daily log & streak
        updateDailyLogAndStreak(userId, 1);

        return progress;
    }

    /**
     * Reset tiến trình học của category
     */
    @Transactional
    public void resetCategoryProgress(Integer userId, Integer categoryId) {
        progressRepository.deleteByUserIdAndCategoryId(userId, categoryId);
    }

    /**
     * Lấy các thẻ cần ôn tập
     */
    public List<StudyProgress> getCardsToReview(Integer userId) {
        return progressRepository.findCardsToReview(userId);
    }

    public List<StudyProgress> getCardsToReviewInCategory(Integer userId, Integer categoryId) {
        return progressRepository.findCardsToReviewInCategory(userId, categoryId);
    }

    // ==================== STREAK ====================

    /**
     * Lấy thông tin streak của user
     */
    public StudyStreakDTO getStreakInfo(Integer userId) {
        StudyStreak streak = streakRepository.findByUserId(userId).orElse(null);
        if (streak == null) {
            streak = new StudyStreak(userId);
            streak = streakRepository.save(streak);
        }

        StudyStreakDTO dto = new StudyStreakDTO();
        dto.setCurrentStreak(streak.getCurrentStreak());
        dto.setLongestStreak(streak.getLongestStreak());
        dto.setLastStudyDate(streak.getLastStudyDate());
        dto.setTotalStudyDays(streak.getTotalStudyDays());
        dto.setHasStudiedToday(streak.hasStudiedToday());
        dto.setIsStreakAtRisk(streak.isStreakAtRisk());

        // Lấy dữ liệu 7 ngày
        dto.setWeeklyData(getWeeklyStudyData(userId));

        return dto;
    }

    /**
     * Lấy dữ liệu học 7 ngày gần nhất
     */
    public List<DailyStudyDTO> getWeeklyStudyData(Integer userId) {
        LocalDate today = LocalDate.now();
        LocalDate startDate = today.minusDays(6);

        List<DailyStudyLog> logs = dailyLogRepository.findByUserIdAndDateRange(userId, startDate, today);

        // Tạo map các ngày đã có log
        Map<LocalDate, DailyStudyLog> logMap = new HashMap<>();
        for (DailyStudyLog log : logs) {
            logMap.put(log.getStudyDate(), log);
        }

        // Tạo danh sách 7 ngày
        List<DailyStudyDTO> weeklyData = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            DailyStudyLog log = logMap.get(date);

            DailyStudyDTO dayDto = new DailyStudyDTO(date, log != null);
            if (log != null) {
                dayDto.setCardsStudied(log.getCardsStudied());
                dayDto.setMinutesSpent(log.getMinutesSpent());
                dayDto.setSessionsCount(log.getSessionsCount());
            }
            weeklyData.add(dayDto);
        }

        return weeklyData;
    }

    /**
     * Cập nhật daily log và streak
     */
    @Transactional
    public void updateDailyLogAndStreak(Integer userId, int cardsStudied) {
        LocalDate today = LocalDate.now();

        // Cập nhật hoặc tạo mới daily log
        DailyStudyLog log = dailyLogRepository.findByUserIdAndStudyDate(userId, today)
                .orElseGet(() -> {
                    DailyStudyLog newLog = new DailyStudyLog();
                    newLog.setUserId(userId);
                    newLog.setStudyDate(today);
                    newLog.setCardsStudied(0);
                    newLog.setMinutesSpent(0);
                    newLog.setSessionsCount(0);
                    return newLog;
                });

        log.setCardsStudied(log.getCardsStudied() + cardsStudied);
        log.setSessionsCount(log.getSessionsCount() + 1);
        dailyLogRepository.save(log);

        // Cập nhật streak
        StudyStreak streak = streakRepository.findByUserId(userId).orElse(null);
        if (streak == null) {
            streak = new StudyStreak(userId);
        }
        streak.recordStudyToday();
        streakRepository.save(streak);
    }

}