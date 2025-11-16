package com.tieuluan.backend.service;

import com.tieuluan.backend.model.OtpVerification;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.OtpVerificationRepository;
import com.tieuluan.backend.repository.UserRepository;
import jakarta.mail.MessagingException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.ZonedDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class OtpService {

    private final OtpVerificationRepository otpRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final SecureRandom random = new SecureRandom();

    // Tạo mã OTP 6 số
    private String generateOtpCode() {
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }

    @Transactional
    public void createAndSendOtp(Long userId, String email) throws MessagingException {
        // Xóa các OTP cũ chưa verify của user này
        otpRepository.deleteByUserId(userId);

        // Tạo OTP mới
        String otpCode = generateOtpCode();
        ZonedDateTime now = ZonedDateTime.now();

        OtpVerification otp = new OtpVerification();
        otp.setUserId(userId);
        otp.setOtpCode(otpCode);
        otp.setCreatedAt(now);
        otp.setExpiresAt(now.plusMinutes(5)); // Hết hạn sau 5 phút
        otp.setIsVerified(false);
        otp.setVerificationType("REGISTRATION");

        otpRepository.save(otp);

        // Gửi email
        emailService.sendOtpEmail(email, otpCode);
    }

    @Transactional
    public boolean verifyOtp(Long userId, String otpCode) {
        Optional<OtpVerification> otpOpt = otpRepository
                .findByUserIdAndOtpCodeAndIsVerifiedFalse(userId, otpCode);

        if (otpOpt.isEmpty()) {
            return false;
        }

        OtpVerification otp = otpOpt.get();

        // Kiểm tra hết hạn
        if (otp.isExpired()) {
            return false;
        }

        // Đánh dấu OTP đã verify
        otp.setIsVerified(true);
        otpRepository.save(otp);

        // Cập nhật status user thành VERIFIED
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        user.setStatus(User.UserStatus.VERIFIED);
        userRepository.save(user);

        return true;
    }

    @Transactional
    public void resendOtp(Long userId) throws MessagingException {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        createAndSendOtp(userId, user.getEmail());
    }
}