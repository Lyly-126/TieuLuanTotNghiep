package com.tieuluan.backend.service;

import com.tieuluan.backend.model.OtpVerification;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.OtpVerificationRepository;
import com.tieuluan.backend.repository.UserRepository;
import jakarta.mail.MessagingException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.ZonedDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ForgotPasswordService {

    private final UserRepository userRepository;
    private final OtpVerificationRepository otpRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom random = new SecureRandom();

    /**
     * Bước 1: Tạo và gửi OTP cho quên mật khẩu
     */
    @Transactional
    public void sendForgotPasswordOtp(String email) throws MessagingException {
        // Kiểm tra email có tồn tại không
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Email không tồn tại trong hệ thống"));

        // Xóa các OTP quên mật khẩu cũ của user này (nếu có)
        otpRepository.deleteByUserId(user.getId());

        // Tạo OTP mới
        String otpCode = generateOtpCode();
        ZonedDateTime now = ZonedDateTime.now();

        OtpVerification otp = new OtpVerification();
        otp.setUserId(user.getId());
        otp.setOtpCode(otpCode);
        otp.setCreatedAt(now);
        otp.setExpiresAt(now.plusMinutes(5)); // Hết hạn sau 5 phút
        otp.setIsVerified(false);
        otp.setVerificationType("FORGOT_PASSWORD"); // Phân biệt với REGISTRATION

        otpRepository.save(otp);

        // Gửi email
        emailService.sendOtpEmail(email, otpCode);
    }

    /**
     * Bước 2: Xác thực OTP cho quên mật khẩu
     */
    @Transactional(readOnly = true)
    public boolean verifyForgotPasswordOtp(String email, String otpCode) {
        // Tìm user theo email
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Email không tồn tại"));

        // Tìm OTP chưa verify của user
        Optional<OtpVerification> otpOpt = otpRepository
                .findByUserIdAndOtpCodeAndIsVerifiedFalse(user.getId(), otpCode);

        if (otpOpt.isEmpty()) {
            return false;
        }

        OtpVerification otp = otpOpt.get();

        // Kiểm tra loại OTP
        if (!"FORGOT_PASSWORD".equals(otp.getVerificationType())) {
            return false;
        }

        // Kiểm tra hết hạn
        if (otp.isExpired()) {
            return false;
        }

        return true;
    }

    /**
     * Bước 3: Đặt lại mật khẩu mới
     */
    @Transactional
    public void resetPassword(String email, String otpCode, String newPassword) {
        // Tìm user
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Email không tồn tại"));

        // Tìm OTP
        Optional<OtpVerification> otpOpt = otpRepository
                .findByUserIdAndOtpCodeAndIsVerifiedFalse(user.getId(), otpCode);

        if (otpOpt.isEmpty()) {
            throw new RuntimeException("Mã OTP không hợp lệ");
        }

        OtpVerification otp = otpOpt.get();

        // Kiểm tra loại OTP
        if (!"FORGOT_PASSWORD".equals(otp.getVerificationType())) {
            throw new RuntimeException("Mã OTP không hợp lệ cho việc đặt lại mật khẩu");
        }

        // Kiểm tra hết hạn
        if (otp.isExpired()) {
            throw new RuntimeException("Mã OTP đã hết hạn");
        }

        // Validate mật khẩu mới
        validatePassword(newPassword);

        // Cập nhật mật khẩu
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Đánh dấu OTP đã sử dụng
        otp.setIsVerified(true);
        otpRepository.save(otp);

        // Xóa tất cả OTP cũ của user để bảo mật
        otpRepository.deleteByUserId(user.getId());
    }

    /**
     * Tạo mã OTP 6 số ngẫu nhiên
     */
    private String generateOtpCode() {
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }

    /**
     * Validate mật khẩu mới
     */
    private void validatePassword(String password) {
        if (password == null || password.length() < 8) {
            throw new RuntimeException("Mật khẩu phải có ít nhất 8 ký tự");
        }
        if (!password.matches("^(?=.*[A-Za-z])(?=.*\\d).*$")) {
            throw new RuntimeException("Mật khẩu phải bao gồm cả chữ và số");
        }
    }
}