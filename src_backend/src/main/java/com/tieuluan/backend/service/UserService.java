package com.tieuluan.backend.service;

import com.tieuluan.backend.util.JwtUtil;
import com.tieuluan.backend.controller.UserController;
import com.tieuluan.backend.dto.UserDTO;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

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
        user.setRole(User.UserRole.USER);

        User savedUser = userRepository.save(user);
        return UserDTO.fromEntity(savedUser);
    }

    public UserDTO.AuthResponse login(UserDTO.LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email hoặc mật khẩu không đúng"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Email hoặc mật khẩu không đúng");
        }

        String token = jwtUtil.generateToken(user.getEmail(), user.getRole().name());

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


    /**
     * Admin: Tìm kiếm người dùng theo email hoặc fullName
     */
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

    /**
     * Admin: Khóa tài khoản (đổi status sang SUSPENDED)
     */
    @Transactional
    public UserDTO lockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // Không cho phép khóa tài khoản ADMIN
        if (user.getRole() == User.UserRole.ADMIN) {
            throw new RuntimeException("Không thể khóa tài khoản Admin");
        }

        user.setStatus(User.UserStatus.SUSPENDED);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    /**
     * Admin: Mở khóa tài khoản (đổi status sang VERIFIED)
     */
    @Transactional
    public UserDTO unlockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        user.setStatus(User.UserStatus.VERIFIED);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    /**
     * Admin: Xóa người dùng (NGUY HIỂM - cân nhắc kỹ)
     */
    @Transactional
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        // Không cho phép xóa tài khoản ADMIN
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

    @Transactional
    public void changePassword(UserController.ChangePasswordRequest request) {
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

    /**
     * Admin: Cấp gói Premium
     */
    @Transactional
    public UserDTO grantPremium(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        user.setIsPremium(true);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    /**
     * Admin: Thu hồi quyền Premium
     */
    @Transactional
    public UserDTO revokePremium(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        user.setIsPremium(false);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }

    /**
     * Admin: Khóa user (sử dụng isBlocked thay vì status)
     */
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

    /**
     * Admin: Mở khóa user
     */
    @Transactional
    public UserDTO unblockUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng"));

        user.setIsBlocked(false);
        User updatedUser = userRepository.save(user);
        return UserDTO.fromEntity(updatedUser);
    }
}