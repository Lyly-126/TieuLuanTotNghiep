package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);      // ✅ Changed from findByUsername
    boolean existsByEmail(String email);           // ✅ Changed from existsByUsername
}