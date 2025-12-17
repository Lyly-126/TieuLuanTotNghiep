package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.UserSavedCategory;
import com.tieuluan.backend.model.UserSavedCategoryId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * UserSavedCategoryRepository - User favorites
 */
@Repository
public interface UserSavedCategoryRepository extends JpaRepository<UserSavedCategory, UserSavedCategoryId> {

    /**
     * Find all saved categories for a user
     */
    List<UserSavedCategory> findByIdUserId(Long userId);

    /**
     * Find all users who saved a category
     */
    List<UserSavedCategory> findByIdCategoryId(Long categoryId);

    /**
     * Check if user saved this category
     */
    boolean existsByIdUserIdAndIdCategoryId(Long userId, Long categoryId);

    /**
     * Unsave category
     */
    void deleteByIdUserIdAndIdCategoryId(Long userId, Long categoryId);

    /**
     * Count saved categories for user
     */
    long countByIdUserId(Long userId);

    /**
     * Count users who saved category
     */
    long countByIdCategoryId(Long categoryId);

    /**
     * Get saved categories with details (JOIN FETCH)
     */
    @Query("SELECT usc FROM UserSavedCategory usc " +
            "JOIN FETCH usc.category c " +
            "WHERE usc.id.userId = :userId " +
            "ORDER BY usc.savedAt DESC")
    List<UserSavedCategory> findSavedCategoriesWithDetails(@Param("userId") Long userId);

    // ✅ Tìm tất cả categories mà user đã save
    @Query("SELECT usc FROM UserSavedCategory usc WHERE usc.id.userId = :userId")
    List<UserSavedCategory> findByUserId(@Param("userId") Long userId);

    // ✅ Kiểm tra user đã save category chưa
    @Query("SELECT CASE WHEN COUNT(usc) > 0 THEN true ELSE false END " +
            "FROM UserSavedCategory usc " +
            "WHERE usc.id.userId = :userId AND usc.id.categoryId = :categoryId")
    boolean existsByUserIdAndCategoryId(@Param("userId") Long userId, @Param("categoryId") Long categoryId);

    // ✅ Đếm số user đã save category
    @Query("SELECT COUNT(usc) FROM UserSavedCategory usc WHERE usc.id.categoryId = :categoryId")
    long countByCategoryId(@Param("categoryId") Long categoryId);
}
