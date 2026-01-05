package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.StudyProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StudyProgressRepository extends JpaRepository<StudyProgress, Integer> {

    /**
     * Tìm progress của một flashcard cho user
     */
    Optional<StudyProgress> findByUserIdAndFlashcardId(Integer userId, Integer flashcardId);

    /**
     * Lấy tất cả progress của user cho một category
     */
    List<StudyProgress> findByUserIdAndCategoryId(Integer userId, Integer categoryId);

    /**
     * Đếm số thẻ đã học (LEARNING + MASTERED) trong category
     */
    @Query("SELECT COUNT(sp) FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId AND sp.status IN ('LEARNING', 'MASTERED')")
    Integer countStudiedCards(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Đếm số thẻ đã MASTERED trong category
     */
    @Query("SELECT COUNT(sp) FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId AND sp.status = 'MASTERED'")
    Integer countMasteredCards(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Đếm số thẻ đang LEARNING trong category
     */
    @Query("SELECT COUNT(sp) FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId AND sp.status = 'LEARNING'")
    Integer countLearningCards(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Lấy các thẻ cần ôn tập (đã đến hạn review)
     */
    @Query("SELECT sp FROM StudyProgress sp WHERE sp.userId = :userId AND sp.nextReviewAt <= CURRENT_TIMESTAMP ORDER BY sp.nextReviewAt")
    List<StudyProgress> findCardsToReview(@Param("userId") Integer userId);

    /**
     * Lấy các thẻ cần ôn tập trong category
     */
    @Query("SELECT sp FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId AND sp.nextReviewAt <= CURRENT_TIMESTAMP ORDER BY sp.nextReviewAt")
    List<StudyProgress> findCardsToReviewInCategory(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Tính tổng số câu đúng trong category
     */
    @Query("SELECT COALESCE(SUM(sp.correctCount), 0) FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId")
    Integer sumCorrectCount(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Tính tổng số câu sai trong category
     */
    @Query("SELECT COALESCE(SUM(sp.incorrectCount), 0) FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId")
    Integer sumIncorrectCount(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Xóa tất cả progress của user trong category (reset progress)
     */
    @Modifying
    @Query("DELETE FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId")
    void deleteByUserIdAndCategoryId(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);

    /**
     * Lấy thống kê theo status cho category
     */
    @Query("SELECT sp.status, COUNT(sp) FROM StudyProgress sp WHERE sp.userId = :userId AND sp.categoryId = :categoryId GROUP BY sp.status")
    List<Object[]> getStatusCountByCategory(@Param("userId") Integer userId, @Param("categoryId") Integer categoryId);
}