package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Flashcard;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FlashcardRepository extends JpaRepository<Flashcard, Long> {

    /**
     * ✅ FIXED: Tìm flashcards theo category ID (dùng relationship)
     */
    @Query("SELECT f FROM Flashcard f WHERE f.category.id = :categoryId")
    List<Flashcard> findByCategoryId(@Param("categoryId") Long categoryId);

    /**
     * Tìm kiếm flashcards theo từ khóa (term hoặc meaning)
     */
    @Query("SELECT f FROM Flashcard f WHERE " +
            "LOWER(f.term) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(f.meaning) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<Flashcard> searchByKeyword(@Param("keyword") String keyword);

    /**
     * Lấy flashcards ngẫu nhiên với limit
     */
    @Query("SELECT f FROM Flashcard f ORDER BY function('RANDOM')")
    List<Flashcard> findRandomFlashcards(Pageable pageable);

    /**
     * Lấy flashcards theo danh sách IDs
     */
    List<Flashcard> findByIdIn(List<Long> ids);

    /**
     * Đếm tổng số flashcards
     */
    @Query("SELECT COUNT(f) FROM Flashcard f")
    Long countTotalFlashcards();

    /**
     * ✅ FIXED: Đếm số flashcards theo category
     */
    @Query("SELECT f.category.id, COUNT(f) FROM Flashcard f WHERE f.category IS NOT NULL GROUP BY f.category.id")
    List<Object[]> countFlashcardsByCategory();

    /**
     * Tìm flashcards có TTS URL
     */
    @Query("SELECT f FROM Flashcard f WHERE f.ttsUrl IS NOT NULL AND f.ttsUrl != ''")
    List<Flashcard> findFlashcardsWithTtsUrl();

    /**
     * Tìm flashcards theo part of speech
     */
    List<Flashcard> findByPartOfSpeech(String partOfSpeech);

    /**
     * Tìm flashcards có hình ảnh
     */
    @Query("SELECT f FROM Flashcard f WHERE f.imageUrl IS NOT NULL AND f.imageUrl != ''")
    List<Flashcard> findFlashcardsWithImages();

    /**
     * ✅ THÊM: Tìm flashcards không có category
     */
    @Query("SELECT f FROM Flashcard f WHERE f.category IS NULL")
    List<Flashcard> findFlashcardsWithoutCategory();
}