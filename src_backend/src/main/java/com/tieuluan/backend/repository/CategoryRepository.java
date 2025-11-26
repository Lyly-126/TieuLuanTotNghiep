package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    Optional<Category> findByName(String name);
    boolean existsByName(String name);

    List<Category> findByOwnerUserId(Long ownerUserId);

    List<Category> findByIsSystemTrue();

    List<Category> findByClassId(Long classId);

    @Query("SELECT c FROM Category c WHERE c.isSystem = true OR c.ownerUserId = :userId")
    List<Category> findAvailableForUser(@Param("userId") Long userId);

    @Query("SELECT c FROM Category c WHERE c.isSystem = true OR c.classId = :classId")
    List<Category> findAvailableForClass(@Param("classId") Long classId);

    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN true ELSE false END FROM Category c " +
            "WHERE c.id = :categoryId AND (c.isSystem = true OR c.ownerUserId = :userId)")
    boolean isAccessibleByUser(@Param("categoryId") Long categoryId, @Param("userId") Long userId);

    @Query("SELECT c FROM Category c WHERE c.ownerUserId = :teacherId")
    List<Category> findByTeacherId(@Param("teacherId") Long teacherId);

    @Query("SELECT COUNT(f) FROM Flashcard f WHERE f.category.id = :categoryId")
    long countFlashcardsInCategory(@Param("categoryId") Long categoryId);
}