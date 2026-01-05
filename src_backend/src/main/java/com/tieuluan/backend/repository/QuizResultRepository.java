package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.QuizResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 📊 QuizResultRepository - Repository cho Quiz Results
 */
@Repository
public interface QuizResultRepository extends JpaRepository<QuizResult, Long> {

    // ===== TÌM KIẾM CƠ BẢN =====

    /**
     * Lấy tất cả kết quả quiz của user
     */
    List<QuizResult> findByUserIdOrderByCompletedAtDesc(Integer userId);

    /**
     * Lấy kết quả quiz của user cho category
     */
    List<QuizResult> findByUserIdAndCategoryIdOrderByCompletedAtDesc(Integer userId, Integer categoryId);

    /**
     * Lấy kết quả quiz gần nhất của user cho category
     */
    Optional<QuizResult> findTopByUserIdAndCategoryIdOrderByCompletedAtDesc(Integer userId, Integer categoryId);

    /**
     * Lấy N kết quả quiz gần nhất của user
     */
    List<QuizResult> findTop10ByUserIdOrderByCompletedAtDesc(Integer userId);

    // ===== THỐNG KÊ =====

    /**
     * Đếm số lần quiz của user
     */
    Integer countByUserId(Integer userId);

    /**
     * Đếm số lần quiz của user cho category
     */
    Integer countByUserIdAndCategoryId(Integer userId, Integer categoryId);

    /**
     * Tính điểm trung bình của user
     */
    @Query("SELECT AVG(qr.score) FROM QuizResult qr WHERE qr.userId = :userId")
    Double getAverageScoreByUser(@Param("userId") Integer userId);

    /**
     * Tính điểm trung bình của user cho category
     */
    @Query("SELECT AVG(qr.score) FROM QuizResult qr WHERE qr.userId = :userId AND qr.categoryId = :categoryId")
    Double getAverageScoreByUserAndCategory(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Lấy điểm cao nhất của user cho category
     */
    @Query("SELECT MAX(qr.score) FROM QuizResult qr WHERE qr.userId = :userId AND qr.categoryId = :categoryId")
    Double getHighestScoreByUserAndCategory(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Đếm số quiz passed (>= 60%) của user
     */
    @Query("SELECT COUNT(qr) FROM QuizResult qr WHERE qr.userId = :userId AND qr.score >= 60")
    Integer countPassedQuizzes(@Param("userId") Integer userId);

    /**
     * Tính tổng số câu đúng của user
     */
    @Query("SELECT COALESCE(SUM(qr.correctAnswers), 0) FROM QuizResult qr WHERE qr.userId = :userId")
    Integer getTotalCorrectAnswers(@Param("userId") Integer userId);

    /**
     * Tính tổng số câu hỏi đã làm của user
     */
    @Query("SELECT COALESCE(SUM(qr.totalQuestions), 0) FROM QuizResult qr WHERE qr.userId = :userId")
    Integer getTotalQuestions(@Param("userId") Integer userId);

    // ===== THỐNG KÊ THEO KỸ NĂNG =====

    /**
     * Tính điểm nghe trung bình
     */
    @Query("SELECT AVG(qr.listeningScore) FROM QuizResult qr WHERE qr.userId = :userId AND qr.listeningScore IS NOT NULL")
    Double getAverageListeningScore(@Param("userId") Integer userId);

    /**
     * Tính điểm đọc trung bình
     */
    @Query("SELECT AVG(qr.readingScore) FROM QuizResult qr WHERE qr.userId = :userId AND qr.readingScore IS NOT NULL")
    Double getAverageReadingScore(@Param("userId") Integer userId);

    /**
     * Tính điểm viết trung bình
     */
    @Query("SELECT AVG(qr.writingScore) FROM QuizResult qr WHERE qr.userId = :userId AND qr.writingScore IS NOT NULL")
    Double getAverageWritingScore(@Param("userId") Integer userId);

    // ===== THỐNG KÊ THEO THỜI GIAN =====

    /**
     * Lấy kết quả quiz trong khoảng thời gian
     */
    List<QuizResult> findByUserIdAndCompletedAtBetweenOrderByCompletedAtDesc(
            Integer userId, LocalDateTime start, LocalDateTime end);

    /**
     * Đếm số quiz trong ngày
     */
    @Query("SELECT COUNT(qr) FROM QuizResult qr WHERE qr.userId = :userId AND DATE(qr.completedAt) = DATE(:date)")
    Integer countQuizzesToday(@Param("userId") Integer userId, @Param("date") LocalDateTime date);

    /**
     * Đếm số quiz trong tuần
     */
    @Query("SELECT COUNT(qr) FROM QuizResult qr WHERE qr.userId = :userId AND qr.completedAt >= :startOfWeek")
    Integer countQuizzesThisWeek(@Param("userId") Integer userId, @Param("startOfWeek") LocalDateTime startOfWeek);

    // ===== LEADERBOARD =====

    /**
     * Lấy top users theo điểm trung bình cho category
     */
    @Query("SELECT qr.userId, AVG(qr.score) as avgScore FROM QuizResult qr " +
            "WHERE qr.categoryId = :categoryId " +
            "GROUP BY qr.userId ORDER BY avgScore DESC")
    List<Object[]> getTopUsersByCategoryScore(@Param("categoryId") Integer categoryId);

    /**
     * Lấy lịch sử quiz theo loại
     */
    List<QuizResult> findByUserIdAndQuizTypeOrderByCompletedAtDesc(Integer userId, QuizResult.QuizType quizType);
}