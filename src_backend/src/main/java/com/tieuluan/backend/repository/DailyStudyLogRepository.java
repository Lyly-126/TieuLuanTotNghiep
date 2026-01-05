package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.DailyStudyLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DailyStudyLogRepository extends JpaRepository<DailyStudyLog, Integer> {

    /**
     * Tìm log theo user và ngày
     */
    Optional<DailyStudyLog> findByUserIdAndStudyDate(Integer userId, LocalDate studyDate);

    /**
     * Lấy logs trong khoảng thời gian
     */
    @Query("SELECT dsl FROM DailyStudyLog dsl WHERE dsl.userId = :userId AND dsl.studyDate BETWEEN :startDate AND :endDate ORDER BY dsl.studyDate DESC")
    List<DailyStudyLog> findByUserIdAndDateRange(
            @Param("userId") Integer userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    /**
     * Lấy N ngày gần nhất
     */
    @Query("SELECT dsl FROM DailyStudyLog dsl WHERE dsl.userId = :userId AND dsl.studyDate >= :startDate ORDER BY dsl.studyDate DESC")
    List<DailyStudyLog> findLastNDays(@Param("userId") Integer userId, @Param("startDate") LocalDate startDate);

    /**
     * Tính tổng thẻ đã học từ ngày
     */
    @Query("SELECT COALESCE(SUM(dsl.cardsStudied), 0) FROM DailyStudyLog dsl WHERE dsl.userId = :userId AND dsl.studyDate >= :startDate")
    Integer sumCardsStudiedSince(@Param("userId") Integer userId, @Param("startDate") LocalDate startDate);

    /**
     * Tính tổng phút học từ ngày
     */
    @Query("SELECT COALESCE(SUM(dsl.minutesSpent), 0) FROM DailyStudyLog dsl WHERE dsl.userId = :userId AND dsl.studyDate >= :startDate")
    Integer sumMinutesSpentSince(@Param("userId") Integer userId, @Param("startDate") LocalDate startDate);
}