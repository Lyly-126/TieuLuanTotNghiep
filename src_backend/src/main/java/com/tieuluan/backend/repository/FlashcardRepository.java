package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Flashcard;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * FlashcardRepository
 *
 * Lưu ý: Sử dụng field "word" thay vì "term"
 */
@Repository
public interface FlashcardRepository extends JpaRepository<Flashcard, Long> {

    // ============ Word Queries ============

    List<Flashcard> findByWord(String word);

    List<Flashcard> findByWordContainingIgnoreCase(String word);

    @Query("SELECT f FROM Flashcard f WHERE LOWER(f.word) = LOWER(:word)")
    List<Flashcard> findByWordIgnoreCase(@Param("word") String word);

    // ============ Category Queries ============

    // ✅ Dùng JPQL query thay vì derived method để tránh lỗi column name case-sensitive
    @Query("SELECT f FROM Flashcard f WHERE f.category.id = :categoryId")
    List<Flashcard> findByCategoryId(@Param("categoryId") Long categoryId);

    @Query("SELECT COUNT(f) FROM Flashcard f WHERE f.category.id = :categoryId")
    long countByCategoryId(@Param("categoryId") Long categoryId);

    @Query("SELECT f FROM Flashcard f WHERE f.category.id = :categoryId ORDER BY f.createdAt DESC")
    List<Flashcard> findByCategoryIdOrderByCreatedAtDesc(@Param("categoryId") Long categoryId);

    // ============ User Queries ============

    @Query("SELECT f FROM Flashcard f WHERE f.user.id = :userId ORDER BY f.createdAt DESC")
    List<Flashcard> findByUserId(@Param("userId") Long userId);

    @Query("SELECT COUNT(f) FROM Flashcard f WHERE f.user.id = :userId")
    long countByUserId(@Param("userId") Long userId);

    @Query("SELECT f FROM Flashcard f WHERE f.user.id = :userId AND f.category.id = :categoryId ORDER BY f.createdAt DESC")
    List<Flashcard> findByUserIdAndCategoryId(@Param("userId") Long userId,
                                              @Param("categoryId") Long categoryId);

    @Query("SELECT f FROM Flashcard f WHERE f.user.id = :userId AND f.category IS NULL ORDER BY f.createdAt DESC")
    List<Flashcard> findByUserIdAndCategoryIsNull(@Param("userId") Long userId);

    // ============ Ownership Check ============

    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END " +
            "FROM Flashcard f WHERE f.id = :flashcardId AND f.user.id = :userId")
    boolean isOwnedByUser(@Param("flashcardId") Long flashcardId, @Param("userId") Long userId);

    // ============ Search Queries ============

    @Query("SELECT f FROM Flashcard f WHERE f.user.id = :userId " +
            "AND (LOWER(f.word) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "OR LOWER(f.meaning) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    List<Flashcard> searchByUserIdAndKeyword(@Param("userId") Long userId,
                                             @Param("keyword") String keyword);

    @Query("SELECT f FROM Flashcard f WHERE " +
            "LOWER(f.word) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "OR LOWER(f.meaning) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<Flashcard> searchByKeyword(@Param("keyword") String keyword);

    // ============ Duplicate Check ============

    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END " +
            "FROM Flashcard f WHERE f.user.id = :userId " +
            "AND f.category.id = :categoryId " +
            "AND LOWER(f.word) = LOWER(:word)")
    boolean existsByUserIdAndCategoryIdAndWord(@Param("userId") Long userId,
                                               @Param("categoryId") Long categoryId,
                                               @Param("word") String word);

    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END " +
            "FROM Flashcard f WHERE f.user.id = :userId " +
            "AND LOWER(f.word) = LOWER(:word)")
    boolean existsByUserIdAndWord(@Param("userId") Long userId, @Param("word") String word);

    // ============ Random ============

    @Query(value = "SELECT * FROM flashcards WHERE \"categoryId\" = :categoryId ORDER BY RANDOM() LIMIT :limit",
            nativeQuery = true)
    List<Flashcard> findRandomByCategoryId(@Param("categoryId") Long categoryId, @Param("limit") int limit);

    @Query(value = "SELECT * FROM flashcards WHERE \"userId\" = :userId ORDER BY RANDOM() LIMIT :limit",
            nativeQuery = true)
    List<Flashcard> findRandomByUserId(@Param("userId") Long userId, @Param("limit") int limit);
}