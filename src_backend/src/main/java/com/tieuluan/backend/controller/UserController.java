// ===================================================
// FIXED USERCONTROLLER - PROPER NULL HANDLING
// ===================================================

package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.UserDTO;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.UserService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final UserService userService;

    // ===================================================
    // ✅ FIXED: LOGIN METHOD - PROPER NULL HANDLING
    // ===================================================

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            // Validate input
            if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                throw new RuntimeException("Email không được để trống");
            }
            if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
                throw new RuntimeException("Mật khẩu không được để trống");
            }

            // Tìm user theo email
            User user = userRepository.findByEmail(request.getEmail().trim())
                    .orElseThrow(() -> new RuntimeException("Email không tồn tại"));

            // Verify password
            if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
                throw new RuntimeException("Mật khẩu không đúng");
            }

            // Check status
            if (user.getStatus() == User.UserStatus.UNVERIFIED) {
                throw new RuntimeException("Tài khoản chưa được xác thực. Vui lòng kiểm tra email");
            }

            if (user.getStatus() == User.UserStatus.SUSPENDED ||
                    user.getStatus() == User.UserStatus.BANNED) {
                throw new RuntimeException("Tài khoản đã bị khóa");
            }

            // ✅ Generate token với userId
            String token = jwtUtil.generateToken(
                    user.getEmail(),
                    user.getRole().name(),
                    user.getId()
            );

            // ✅ Build user info với null-safe handling
            String fullName = user.getFullName();
            if (fullName == null || fullName.trim().isEmpty()) {
                fullName = user.getEmail().split("@")[0];
            }

            Map<String, Object> userInfo = new HashMap<>();
            userInfo.put("id", user.getId());
            userInfo.put("email", user.getEmail());
            userInfo.put("fullName", fullName);  // ← KHÔNG BAO GIỜ NULL
            userInfo.put("role", user.getRole().name());
            userInfo.put("status", user.getStatus().name());
            userInfo.put("isBlocked", user.getIsBlocked() != null ? user.getIsBlocked() : false);

            // ✅ Response với token và user info
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Đăng nhập thành công");
            response.put("token", token);
            response.put("user", userInfo);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "success", false,
                            "message", e.getMessage()
                    ));
        }
    }

    // ===================================================
    // ✅ FIXED: REGISTER METHOD
    // ===================================================

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            // Validate input
            if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                throw new RuntimeException("Email không được để trống");
            }
            if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
                throw new RuntimeException("Mật khẩu không được để trống");
            }

            // Validate email exists
            if (userRepository.findByEmail(request.getEmail().trim()).isPresent()) {
                throw new RuntimeException("Email đã tồn tại");
            }

            // Create new user
            User newUser = new User();
            newUser.setEmail(request.getEmail().trim());
            newUser.setPasswordHash(passwordEncoder.encode(request.getPassword()));

            // Set fullName - KHÔNG BAO GIỜ ĐỂ NULL
            String fullName = request.getFullName();
            if (fullName == null || fullName.trim().isEmpty()) {
                fullName = request.getEmail().split("@")[0];
            }
            newUser.setFullName(fullName);

            newUser.setRole(User.UserRole.NORMAL_USER);
            newUser.setStatus(User.UserStatus.UNVERIFIED); // Cần verify OTP
            newUser.setIsBlocked(false);

            // Set dob if provided
            if (request.getDob() != null) {
                newUser.setDob(request.getDob());
            }

            User savedUser = userRepository.save(newUser);

            // ✅ Response
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Đăng ký thành công. Vui lòng kiểm tra email để xác thực tài khoản");
            response.put("id", savedUser.getId());
            response.put("email", savedUser.getEmail());
            response.put("fullName", savedUser.getFullName());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "success", false,
                            "message", e.getMessage()
                    ));
        }
    }


    // ==================== USER & ADMIN ENDPOINTS ====================

    @GetMapping("/{id}")
    public ResponseEntity<?> getUserById(@PathVariable Long id) {
        try {
            UserDTO user = userService.getUserById(id);
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/email/{email}")
    public ResponseEntity<?> getUserByEmail(@PathVariable String email) {
        try {
            UserDTO user = userService.getUserByEmail(email);
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id,
                                        @RequestBody UserDTO.UpdateRequest request) {
        try {
            UserDTO user = userService.updateUser(id, request);
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}/profile")
    public ResponseEntity<?> updateUserProfile(@PathVariable Long id,
                                               @RequestBody UserDTO.UpdateProfileRequest request) {
        try {
            UserDTO user = userService.updateUserProfile(id, request);
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/delete")
    public ResponseEntity<?> deleteOwnAccount() {
        try {
            userService.deleteOwnAccount();
            return ResponseEntity.ok(Map.of("message", "Xóa tài khoản thành công"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(@RequestBody UserService.ChangePasswordRequest request) {
        try {
            userService.changePassword(request);
            return ResponseEntity.ok(Map.of("message", "Đổi mật khẩu thành công"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    // ==================== ADMIN ONLY ENDPOINTS ====================

    /**
     * Admin: Lấy tất cả users
     */
    @GetMapping("/admin/all")
    public ResponseEntity<List<UserDTO>> getAllUsers() {
        try {
            List<UserDTO> users = userService.getAllUsers();
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Admin: Tìm kiếm users
     */
    @GetMapping("/admin/search")
    public ResponseEntity<List<UserDTO>> searchUsers(@RequestParam String keyword) {
        try {
            List<UserDTO> users = userService.searchUsers(keyword);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Admin: Lấy chi tiết user
     */
    @GetMapping("/admin/{id}")
    public ResponseEntity<?> getUserDetail(@PathVariable Long id) {
        try {
            UserDTO user = userService.getUserById(id);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Khóa user
     */
    @PutMapping("/admin/{id}/block")
    public ResponseEntity<?> blockUser(@PathVariable Long id) {
        try {
            UserDTO user = userService.blockUser(id);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Mở khóa user
     */
    @PutMapping("/admin/{id}/unblock")
    public ResponseEntity<?> unblockUser(@PathVariable Long id) {
        try {
            UserDTO user = userService.unblockUser(id);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    // ✅ ĐÚNG - Thêm body parameter với packId
    /**
     * Admin: Cấp gói Premium cho user
     * Body: { "packId": 1 }
     */
    @PutMapping("/admin/{id}/grant-premium")
    public ResponseEntity<?> grantPremium(
            @PathVariable Long id,
            @RequestBody Map<String, Long> body) {
        try {
            Long packId = body.get("packId");
            if (packId == null) {
                return ResponseEntity.badRequest().body(Map.of("message", "Vui lòng chọn gói"));
            }
            UserDTO user = userService.grantPremium(id, packId);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Thu hồi quyền Premium
     */
    @PutMapping("/admin/{id}/revoke-premium")
    public ResponseEntity<?> revokePremium(@PathVariable Long id) {
        try {
            UserDTO user = userService.revokePremium(id);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Xóa user
     */
    @DeleteMapping("/admin/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        try {
            userService.deleteUser(id);
            return ResponseEntity.ok(Map.of("message", "Đã xóa người dùng"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Thăng cấp lên Admin
     */
    @PutMapping("/admin/{id}/promote")
    public ResponseEntity<?> promoteUserToAdmin(@PathVariable Long id) {
        try {
            UserDTO user = userService.promoteToAdmin(id);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Admin: Đổi status user
     */
    @PutMapping("/admin/{id}/status")
    public ResponseEntity<?> changeStatus(@PathVariable Long id, @RequestParam String status) {
        try {
            UserDTO user = userService.changeUserStatus(id, status);
            return ResponseEntity.ok(user);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }


    // ===================================================
    // DTOs
    // ===================================================

    public static class LoginRequest {
        private String email;
        private String password;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    public static class RegisterRequest {
        private String email;
        private String password;
        private String fullName;
        private java.time.LocalDate dob;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getFullName() { return fullName; }
        public void setFullName(String fullName) { this.fullName = fullName; }
        public java.time.LocalDate getDob() { return dob; }
        public void setDob(java.time.LocalDate dob) { this.dob = dob; }
    }
}