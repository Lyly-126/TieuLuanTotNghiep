package com.tieuluan.backend.service;

import com.tieuluan.backend.util.JwtUtil;
import com.tieuluan.backend.dto.UserDTO;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.model.Order;
import com.tieuluan.backend.model.StudyPack;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.repository.OrderRepository;
import com.tieuluan.backend.repository.StudyPackRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final OrderRepository orderRepository;
    private final StudyPackRepository studyPackRepository;

    @Transactional
    public UserDTO registerUser(UserDTO.RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email đã được sử dụng");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setFullName(request.getEmail().split("@")[0]);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setDob(request.getDob());
        user.setStatus(User.UserStatus.UNVERIFIED);
        user.setRole(User.UserRole.NORMAL_USER);

        User savedUser = userRepository.save(user);
        return UserDTO.fromEntity(savedUser);
    }

    // ✅ FIX: Update login với userId trong token
    public UserDTO.AuthResponse login(UserDTO.LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email hoặc mật khẩu không đúng"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Email hoặc mật khẩu không đúng");
        }

        // ✅ FIX: Generate token WITH userId
        String token = jwtUtil.generateToken(
                user.getEmail(),
                user.getRole().name(),
                user.getId()
        );

        UserDTO userDTO = UserDTO.fromEntity(user);
        return new UserDTO.AuthResponse(token, userDTO);
    }

    public UserDTO getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        return UserDTO.fromEntity(user);
    }

    public UserDTO getUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        return UserDTO.fromEntity(user);
    }

    @Transactional
    public UserDTO updateUser(Long id, UserDTO.UpdateRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        if (request.getDob() != null) {
            user.setDob(request.getDob());
        }

        if (request.getStatus() != null) {
            user.setStatus(User.UserStatus.valueOf(request.getStatus()));
        }

        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public void deleteOwnAccount() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserEmail = authentication.getName();

        User user = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        userRepository.delete(user);
    }

    // ================== ADMIN METHODS ==================

    public List<UserDTO> getAllUsers() {
        return userRepository.findAll().stream()
                .map(UserDTO::fromEntity)
                .collect(Collectors.toList());
    }

    public List<UserDTO> searchUsers(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return getAllUsers();
        }

        String searchKeyword = keyword.trim().toLowerCase();

        return userRepository.findAll().stream()
                .filter(user ->
                        user.getEmail().toLowerCase().contains(searchKeyword) ||
                                (user.getFullName() != null && user.getFullName().toLowerCase().contains(searchKeyword))
                )
                .map(UserDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public UserDTO lockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        if (user.getRole() == User.UserRole.ADMIN) {
            throw new RuntimeException("Không thể khóa tài khoản Admin");
        }

        user.setStatus(User.UserStatus.SUSPENDED);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public UserDTO unlockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        user.setStatus(User.UserStatus.VERIFIED);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        if (user.getRole() == User.UserRole.ADMIN) {
            throw new RuntimeException("Không thể xóa tài khoản Admin");
        }

        userRepository.deleteById(id);
    }

    @Transactional
    public UserDTO promoteToAdmin(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        user.setRole(User.UserRole.ADMIN);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public UserDTO changeUserStatus(Long id, String status) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));
        user.setStatus(User.UserStatus.valueOf(status));
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    // ✅ FIX: Thêm ChangePasswordRequest DTO vào đây
    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserEmail = authentication.getName();

        User user = userRepository.findByEmail(currentUserEmail)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Mật khẩu hiện tại không đúng");
        }

        String newPassword = request.getNewPassword();
        if (newPassword == null || newPassword.length() < 8) {
            throw new RuntimeException("Mật khẩu phải có ít nhất 8 ký tự");
        }
        if (!newPassword.matches("^(?=.*[A-Za-z])(?=.*\\d).*$")) {
            throw new RuntimeException("Mật khẩu phải gồm chữ và số");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    @Transactional
    public UserDTO updateUserProfile(Long id, UserDTO.UpdateProfileRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserEmail = authentication.getName();

        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(auth -> auth.getAuthority().equals("ROLE_ADMIN"));

        if (!isAdmin && !user.getEmail().equals(currentUserEmail)) {
            throw new RuntimeException("Bạn không có quyền cập nhật thông tin người dùng này");
        }

        if (request.getFullName() != null && !request.getFullName().trim().isEmpty()) {
            user.setFullName(request.getFullName().trim());
        }

        if (request.getDob() != null) {
            user.setDob(request.getDob());
        }

        if (request.getStatus() != null && isAdmin) {
            user.setStatus(User.UserStatus.valueOf(request.getStatus()));
        }

        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public UserDTO blockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        if (user.getRole() == User.UserRole.ADMIN) {
            throw new RuntimeException("Không thể khóa tài khoản Admin");
        }

        user.setIsBlocked(true);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public UserDTO unblockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        user.setIsBlocked(false);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public UserDTO grantPremium(Long userId, Long packId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        StudyPack pack = studyPackRepository.findById(packId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy gói"));

        Order order = new Order();
        order.setUserId(userId);
        order.setPackId(packId);
        order.setPriceAtPurchase(BigDecimal.ZERO);
        order.setStatus(Order.OrderStatus.PAID);
        order.setStartedAt(ZonedDateTime.now());
        order.setExpiresAt(ZonedDateTime.now().plusDays(pack.getDurationDays()));
        orderRepository.save(order);

        if (pack.getTargetRole() == StudyPack.TargetRole.TEACHER) {
            user.setRole(User.UserRole.TEACHER);
        } else {
            if (user.getRole() == User.UserRole.NORMAL_USER) {
                user.setRole(User.UserRole.PREMIUM_USER);
            }
        }

        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    @Transactional
    public UserDTO revokePremium(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        List<Order> activeOrders = orderRepository.findByUserIdAndStatus(id, Order.OrderStatus.PAID);
        for (Order order : activeOrders) {
            order.setStatus(Order.OrderStatus.CANCELED);
            order.setExpiresAt(ZonedDateTime.now());
            orderRepository.save(order);
        }

        if (user.getRole() == User.UserRole.PREMIUM_USER || user.getRole() == User.UserRole.TEACHER) {
            user.setRole(User.UserRole.NORMAL_USER);
        }

        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    // ✅ NEW: DTO for Change Password Request
    public static class ChangePasswordRequest {
        private String currentPassword;
        private String newPassword;

        public ChangePasswordRequest() {}

        public ChangePasswordRequest(String currentPassword, String newPassword) {
            this.currentPassword = currentPassword;
            this.newPassword = newPassword;
        }

        public String getCurrentPassword() {
            return currentPassword;
        }

        public void setCurrentPassword(String currentPassword) {
            this.currentPassword = currentPassword;
        }

        public String getNewPassword() {
            return newPassword;
        }

        public void setNewPassword(String newPassword) {
            this.newPassword = newPassword;
        }
    }
}