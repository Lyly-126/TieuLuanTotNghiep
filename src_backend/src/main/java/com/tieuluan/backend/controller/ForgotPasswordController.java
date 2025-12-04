package com.tieuluan.backend.controller;

import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.ForgotPasswordService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth/forgot-password")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ForgotPasswordController {

    private final ForgotPasswordService forgotPasswordService;
    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    /**
     * ✅ Bước 1: Gửi OTP qua email
     */
    @PostMapping("/send-otp")
    public ResponseEntity<?> sendOtp(@RequestBody SendOtpRequest request) {
        try {
            // Gửi OTP cho quên mật khẩu
            forgotPasswordService.sendForgotPasswordOtp(request.getEmail());

            // Chuyển sang màn hình nhập OTP
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Mã OTP đã được gửi đến " + request.getEmail()
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "success", false,
                            "message", e.getMessage()
                    ));
        }
    }

    /**
     * ✅ Bước 2: Verify OTP
     */
    @PostMapping("/check-otp")
    public ResponseEntity<?> checkOtp(@RequestBody CheckOtpRequest request) {
        try {
            boolean isValid = forgotPasswordService.verifyForgotPasswordOtp(
                    request.getEmail(),
                    request.getOtp()
            );

            if (isValid) {
                // Chuyển sang màn hình đặt lại mật khẩu
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", "OTP hợp lệ. Vui lòng nhập mật khẩu mới"
                ));
            } else {
                return ResponseEntity.badRequest()
                        .body(Map.of(
                                "success", false,
                                "message", "OTP không đúng hoặc đã hết hạn"
                        ));
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "success", false,
                            "message", e.getMessage()
                    ));
        }
    }

    /**
     * ✅ Bước 3: Đặt lại mật khẩu mới và generate JWT token
     */
    @PostMapping("/reset")
    public ResponseEntity<?> resetPassword(@RequestBody ResetPasswordRequest request) {
        try {
            // Reset password
            forgotPasswordService.resetPassword(
                    request.getEmail(),
                    request.getOtp(),
                    request.getNewPassword()
            );

            // ✅ Lấy thông tin user sau khi reset
            User user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // ✅ Generate token với userId (auto-login sau reset password)
            String token = jwtUtil.generateToken(
                    user.getEmail(),
                    user.getRole().name(),
                    user.getId()  // ← THÊM userId
            );

            // ✅ Response với token để auto-login
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Đặt lại mật khẩu thành công");
            response.put("token", token);
            response.put("user", Map.of(
                    "id", user.getId(),
                    "email", user.getEmail(),
                    "fullName", user.getFullName(),
                    "role", user.getRole().name()
            ));

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "success", false,
                            "message", e.getMessage()
                    ));
        }
    }

    // =============== DTOs ===============

    public static class SendOtpRequest {
        private String email;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }

    public static class CheckOtpRequest {
        private String email;
        private String otp;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getOtp() { return otp; }
        public void setOtp(String otp) { this.otp = otp; }
    }

    public static class ResetPasswordRequest {
        private String email;
        private String otp;
        private String newPassword;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getOtp() { return otp; }
        public void setOtp(String otp) { this.otp = otp; }
        public String getNewPassword() { return newPassword; }
        public void setNewPassword(String newPassword) { this.newPassword = newPassword; }
    }
}