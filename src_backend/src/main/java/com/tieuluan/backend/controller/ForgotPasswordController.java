package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.ForgotPasswordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth/forgot-password")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ForgotPasswordController {

    private final ForgotPasswordService forgotPasswordService;

    @PostMapping("/send-otp")
    public ResponseEntity<?> sendOtp(@RequestBody SendOtpRequest request) {
        try {
            // Gửi OTP cho quên mật khẩu
            forgotPasswordService.sendForgotPasswordOtp(request.getEmail());

            // Chuyển sang màn hình nhập OTP
            return ResponseEntity.ok().body(new MessageResponse("Mã OTP đã được gửi"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/check-otp")
    public ResponseEntity<?> checkOtp(@RequestBody CheckOtpRequest request) {
        try {
            boolean isValid = forgotPasswordService.verifyForgotPasswordOtp(
                    request.getEmail(),
                    request.getOtp()
            );

            if (isValid) {
                // Chuyển sang màn hình đặt lại mật khẩu
                return ResponseEntity.ok().body(new MessageResponse("OTP hợp lệ"));
            } else {
                return ResponseEntity.badRequest().body(new MessageResponse("OTP không đúng"));
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    /**
     * Bước 3: Đặt lại mật khẩu mới
     */
    @PostMapping("/reset")
    public ResponseEntity<?> resetPassword(@RequestBody ResetPasswordRequest request) {
        try {
            forgotPasswordService.resetPassword(
                    request.getEmail(),
                    request.getOtp(),
                    request.getNewPassword()
            );
            return ResponseEntity.ok().body(new MessageResponse("Đặt lại mật khẩu thành công"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
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

    public static class MessageResponse {
        private String message;

        public MessageResponse(String message) {
            this.message = message;
        }

        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }
}