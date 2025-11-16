package com.tieuluan.backend.repository;

import com.tieuluan.backend.model.OtpVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OtpVerificationRepository extends JpaRepository<OtpVerification, Long> {

    Optional<OtpVerification> findByUserIdAndOtpCodeAndIsVerifiedFalse(Long userId, String otpCode);

    Optional<OtpVerification> findFirstByUserIdAndIsVerifiedFalseOrderByCreatedAtDesc(Long userId);

    void deleteByUserId(Long userId);
}