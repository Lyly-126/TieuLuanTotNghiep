package com.tieuluan.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.ZonedDateTime;

@Entity
@Table(name = "otpVerification")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OtpVerification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "userId", nullable = false)
    private Long userId;

    @Column(name = "otpCode", nullable = false, length = 6)
    private String otpCode;

    @Column(name = "createdAt", nullable = false)
    private ZonedDateTime createdAt = ZonedDateTime.now();

    @Column(name = "expiresAt", nullable = false)
    private ZonedDateTime expiresAt;

    @Column(name = "isVerified", nullable = false)
    private Boolean isVerified = false;

    @Column(name = "verificationType", nullable = false, length = 50)
    private String verificationType = "REGISTRATION";

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = ZonedDateTime.now();
        }
        if (expiresAt == null) {
            // OTP hết hạn sau 5 phút
            expiresAt = createdAt.plusMinutes(5);
        }
        if (isVerified == null) {
            isVerified = false;
        }
    }

    public boolean isExpired() {
        return ZonedDateTime.now().isAfter(expiresAt);
    }
}