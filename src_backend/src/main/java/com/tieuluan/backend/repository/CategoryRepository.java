package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * CategoryRepository - ONE-TO-MANY Architecture
 * ✅ Category has classId (nullable)
 * ✅ FIXED: Removed createdAt from ORDER BY (field doesn't exist in DB)
 */
@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    // ============ Basic Queries ============

    Optional<Category> findByName(String name);

    boolean existsByName(String name);

    // ============ ONE-TO-MANY Queries ============

    /**
     * Find categories in a class
     */
    List<Category> findByClassId(Long classId);

    /**
     * Count categories in a class
     */
    long countByClassId(Long classId);

    /**
     * Find independent categories (not in any class)
     */
    List<Category> findByClassIdIsNull();

    // ============ Owner Queries ============

    List<Category> findByOwnerUserId(Long ownerUserId);

    List<Category> findByOwnerUserIdAndClassId(Long ownerUserId, Long classId);

    // ============ System Queries ============

    List<Category> findByIsSystemTrue();

    Optional<Category> findByIdAndIsSystemTrue(Long id);

    // ============ Visibility Queries ============

    List<Category> findByVisibility(String visibility);

    /**
     * Find PUBLIC categories (for sharing)
     * ✅ FIXED: Order by id instead of createdAt (which doesn't exist in DB)
     */
    @Query("SELECT c FROM Category c WHERE c.visibility = 'PUBLIC' ORDER BY c.id DESC")
    List<Category> findPublicCategories();

    // ============ Available Queries ============

    @Query("SELECT c FROM Category c WHERE c.isSystem = true OR c.ownerUserId = :userId")
    List<Category> findAvailableForUser(@Param("userId") Long userId);

    @Query("SELECT c FROM Category c WHERE c.isSystem = true OR c.classId = :classId")
    List<Category> findAvailableForClass(@Param("classId") Long classId);

    // ============ Access Control ============

    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN true ELSE false END FROM Category c " +
            "WHERE c.id = :categoryId AND (c.isSystem = true OR c.ownerUserId = :userId)")
    boolean isAccessibleByUser(@Param("categoryId") Long categoryId, @Param("userId") Long userId);

    // ============ Teacher Queries ============

    @Query("SELECT c FROM Category c WHERE c.ownerUserId = :teacherId")
    List<Category> findByTeacherId(@Param("teacherId") Long teacherId);

    // ============ Statistics ============

    @Query("SELECT COUNT(f) FROM Flashcard f WHERE f.category.id = :categoryId")
    long countFlashcardsInCategory(@Param("categoryId") Long categoryId);

    long countByOwnerUserId(Long ownerUserId);

    long countByVisibility(String visibility);

    long countByIsSystemTrue();

    // ✅ THÊM: Tìm kiếm public categories
    @Query("SELECT c FROM Category c WHERE " +
            "(c.isSystem = true OR c.visibility = 'PUBLIC') AND " +
            "(LOWER(c.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(c.description) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    List<Category> searchPublicCategories(@Param("keyword") String keyword);

    // ✅ THÊM: Lấy public categories
    @Query("SELECT c FROM Category c WHERE c.isSystem = true OR c.visibility = 'PUBLIC'")
    List<Category> findAllPublicCategories();
}
