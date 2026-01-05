package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.StudyStreak;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StudyStreakRepository extends JpaRepository<StudyStreak, Integer> {

    Optional<StudyStreak> findByUserId(Integer userId);

    /**
     * Lấy top users theo current streak
     */
    @Query("SELECT ss FROM StudyStreak ss ORDER BY ss.currentStreak DESC")
    List<StudyStreak> findTopByCurrentStreak();

    /**
     * Lấy top users theo longest streak
     */
    @Query("SELECT ss FROM StudyStreak ss ORDER BY ss.longestStreak DESC")
    List<StudyStreak> findTopByLongestStreak();

    /**
     * Lấy users có streak đang bị đe dọa (chưa học hôm nay và có streak > 0)
     */
    @Query("SELECT ss FROM StudyStreak ss WHERE ss.lastStudyDate < CURRENT_DATE AND ss.currentStreak > 0")
    List<StudyStreak> findStreaksAtRisk();
}
