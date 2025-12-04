package com.tieuluan.backend.controller;

import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.OtpService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/otp")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OtpController {

    private final OtpService otpService;
    private final JwtUtil jwtUtil;
    private final UserRepository userRepository;

    /**
     * ✅ Verify OTP và generate JWT token
     */
    @PostMapping("/verify")
    public ResponseEntity<?> verifyOtp(@RequestBody VerifyOtpRequest request) {
        try {
            boolean isValid = otpService.verifyOtp(request.getUserId(), request.getOtpCode());

            if (isValid) {
                // ✅ Lấy thông tin user
                User user = userRepository.findById(request.getUserId())
                        .orElseThrow(() -> new RuntimeException("User not found"));

                // ✅ Generate token với userId
                String token = jwtUtil.generateToken(
                        user.getEmail(),
                        user.getRole().name(),
                        user.getId()  // ← THÊM userId
                );

                // ✅ Cập nhật status user nếu cần (verify email)
                if ("PENDING".equals(user.getStatus())) {
                    user.setStatus(User.UserStatus.valueOf("ACTIVE"));
                    userRepository.save(user);
                }

                // ✅ Response với token
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Xác thực thành công");
                response.put("token", token);
                response.put("user", Map.of(
                        "id", user.getId(),
                        "email", user.getEmail(),
                        "fullName", user.getFullName(),
                        "role", user.getRole().name()
                ));

                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.badRequest()
                        .body(Map.of(
                                "success", false,
                                "message", "Mã OTP không đúng hoặc đã hết hạn"
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
     * ✅ Resend OTP
     */
    @PostMapping("/resend")
    public ResponseEntity<?> resendOtp(@RequestBody ResendOtpRequest request) {
        try {
            otpService.resendOtp(request.getUserId());

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Đã gửi lại mã OTP"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "success", false,
                            "message", e.getMessage()
                    ));
        }
    }

    // =============== DTOs ===============

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