package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Dictionary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository để truy vấn bảng dictionary
 */
@Repository
public interface DictionaryRepository extends JpaRepository<Dictionary, Long> {

    /**
     * Tìm chính xác theo từ (không phân biệt hoa thường)
     */
    @Query("SELECT d FROM Dictionary d WHERE LOWER(d.word) = LOWER(:word)")
    Optional<Dictionary> findByWordIgnoreCase(@Param("word") String word);

    /**
     * Tìm từ bắt đầu bằng prefix (cho autocomplete)
     */
    @Query("SELECT d FROM Dictionary d WHERE LOWER(d.word) LIKE LOWER(CONCAT(:prefix, '%')) ORDER BY d.word LIMIT 10")
    List<Dictionary> findByWordStartingWith(@Param("prefix") String prefix);

    /**
     * Tìm từ chứa keyword
     */
    @Query("SELECT d FROM Dictionary d WHERE LOWER(d.word) LIKE LOWER(CONCAT('%', :keyword, '%')) ORDER BY d.word LIMIT 20")
    List<Dictionary> findByWordContaining(@Param("keyword") String keyword);

    /**
     * Kiểm tra từ có tồn tại không
     */
    @Query("SELECT CASE WHEN COUNT(d) > 0 THEN true ELSE false END FROM Dictionary d WHERE LOWER(d.word) = LOWER(:word)")
    boolean existsByWord(@Param("word") String word);

    /**
     * Đếm tổng số từ trong từ điển
     */
    @Query("SELECT COUNT(d) FROM Dictionary d")
    long countAll();
}