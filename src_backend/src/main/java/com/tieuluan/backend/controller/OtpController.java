package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.OtpService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/otp")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OtpController {

    private final OtpService otpService;

    @PostMapping("/verify")
    public ResponseEntity<?> verifyOtp(@RequestBody VerifyOtpRequest request) {
        try {
            boolean isValid = otpService.verifyOtp(request.getUserId(), request.getOtpCode());

            if (isValid) {
                return ResponseEntity.ok("Xác thực thành công");
            } else {
                return ResponseEntity.badRequest().body("Mã OTP không đúng hoặc đã hết hạn");
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/resend")
    public ResponseEntity<?> resendOtp(@RequestBody ResendOtpRequest request) {
        try {
            otpService.resendOtp(request.getUserId());
            return ResponseEntity.ok("Đã gửi lại mã OTP");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // DTOs
    public static class VerifyOtpRequest {
        private Long userId;
        private String otpCode;

        public Long getUserId() { return userId; }
        public void setUserId(Long userId) { this.userId = userId; }
        public String getOtpCode() { return otpCode; }
        public void setOtpCode(String otpCode) { this.otpCode = otpCode; }
    }

    public static class ResendOtpRequest {
        private Long userId;

        public Long getUserId() { return userId; }
        public void setUserId(Long userId) { this.userId = userId; }
    }
}