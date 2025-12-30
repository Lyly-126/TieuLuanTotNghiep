package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * CategoryRepository
 * ✅ FIXED: Use cm.id.classId and cm.id.userId for EmbeddedId (ClassMemberId)
 */
@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    // ============ Basic Queries ============

    Optional<Category> findByName(String name);
    boolean existsByName(String name);

    // ============ ONE-TO-MANY Queries ============

    List<Category> findByClassId(Long classId);
    long countByClassId(Long classId);
    List<Category> findByClassIdIsNull();

    // ============ Owner Queries ============

    List<Category> findByOwnerUserId(Long ownerUserId);
    List<Category> findByOwnerUserIdAndClassId(Long ownerUserId, Long classId);

    // ============ System Queries ============

    List<Category> findByIsSystemTrue();
    Optional<Category> findByIdAndIsSystemTrue(Long id);

    // ============ Visibility Queries ============

    List<Category> findByVisibility(String visibility);

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

    // ============ Search ============

    @Query("SELECT c FROM Category c WHERE " +
            "(c.isSystem = true OR c.visibility = 'PUBLIC') AND " +
            "(LOWER(c.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(c.description) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    List<Category> searchPublicCategories(@Param("keyword") String keyword);

    @Query("SELECT c FROM Category c WHERE c.isSystem = true OR c.visibility = 'PUBLIC'")
    List<Category> findAllPublicCategories();

    // ============ NEW: For CategorySuggestionService ============

    /**
     * ✅ FIXED: Lấy categories từ classes mà user là member
     * Sử dụng cm.id.classId và cm.id.userId vì ClassMember dùng @EmbeddedId
     */
    @Query("SELECT DISTINCT c FROM Category c " +
            "JOIN ClassMember cm ON c.classId = cm.id.classId " +
            "WHERE c.classId IS NOT NULL " +
            "AND cm.id.userId = :userId " +
            "AND cm.status = 'APPROVED'")
    List<Category> findAccessibleByUserId(@Param("userId") Long userId);

    /**
     * ✅ FIXED: Lấy TẤT CẢ categories user có thể access
     * Bao gồm: System, Owned by user, Public, và từ Classes đã join
     */
    @Query("SELECT DISTINCT c FROM Category c " +
            "LEFT JOIN ClassMember cm ON c.classId = cm.id.classId AND cm.id.userId = :userId " +
            "WHERE c.isSystem = true " +
            "OR c.ownerUserId = :userId " +
            "OR c.visibility = 'PUBLIC' " +
            "OR (c.classId IS NOT NULL AND cm.status = 'APPROVED')")
    List<Category> findAllAccessibleByUserId(@Param("userId") Long userId);
}