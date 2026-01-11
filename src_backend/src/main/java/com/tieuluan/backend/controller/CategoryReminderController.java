package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.CategoryReminderDTO;
import com.tieuluan.backend.dto.UpdateCategoryReminderRequest;
import com.tieuluan.backend.service.CategoryReminderService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller cho Category Reminder
 * ✅ Sử dụng Long cho categoryId
 *
 * Endpoints:
 * - GET    /api/category-reminder/{categoryId}        → Lấy reminder của 1 category
 * - GET    /api/category-reminder                     → Lấy tất cả reminders
 * - GET    /api/category-reminder/active              → Lấy reminders đang bật
 * - PUT    /api/category-reminder/{categoryId}        → Cập nhật reminder
 * - POST   /api/category-reminder/{categoryId}/toggle → Bật/tắt reminder
 * - DELETE /api/category-reminder/{categoryId}        → Xóa reminder
 */
@Slf4j
@RestController
@RequestMapping("/api/category-reminder")
@RequiredArgsConstructor
public class CategoryReminderController {

    private final CategoryReminderService reminderService;
    private final JwtUtil jwtUtil;

    // ==================== GET ====================

    /**
     * GET /api/category-reminder/{categoryId}
     * Lấy reminder của 1 category
     */
    @GetMapping("/{categoryId}")
    public ResponseEntity<?> getReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId) {
        try {
            Long userId = extractUserId(authHeader);
            CategoryReminderDTO reminder = reminderService.getReminder(userId, categoryId);
            return ResponseEntity.ok(reminder);
        } catch (Exception e) {
            log.error("❌ getReminder error: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/category-reminder
     * Lấy tất cả reminders của user
     */
    @GetMapping
    public ResponseEntity<?> getAllReminders(
            @RequestHeader("Authorization") String authHeader) {
        try {
            Long userId = extractUserId(authHeader);
            List<CategoryReminderDTO> reminders = reminderService.getAllReminders(userId);
            return ResponseEntity.ok(reminders);
        } catch (Exception e) {
            log.error("❌ getAllReminders error: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/category-reminder/active
     * Lấy reminders đang bật
     */
    @GetMapping("/active")
    public ResponseEntity<?> getActiveReminders(
            @RequestHeader("Authorization") String authHeader) {
        try {
            Long userId = extractUserId(authHeader);
            List<CategoryReminderDTO> reminders = reminderService.getActiveReminders(userId);
            return ResponseEntity.ok(Map.of(
                    "reminders", reminders,
                    "count", reminders.size()
            ));
        } catch (Exception e) {
            log.error("❌ getActiveReminders error: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==================== UPDATE ====================

    /**
     * PUT /api/category-reminder/{categoryId}
     * Cập nhật reminder
     */
    @PutMapping("/{categoryId}")
    public ResponseEntity<?> updateReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId,
            @RequestBody UpdateCategoryReminderRequest request) {
        try {
            Long userId = extractUserId(authHeader);
            CategoryReminderDTO reminder = reminderService.updateReminder(userId, categoryId, request);
            return ResponseEntity.ok(reminder);
        } catch (Exception e) {
            log.error("❌ updateReminder error: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/category-reminder/{categoryId}/toggle
     * Bật/tắt reminder nhanh
     */
    @PostMapping("/{categoryId}/toggle")
    public ResponseEntity<?> toggleReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId,
            @RequestBody Map<String, Boolean> body) {
        try {
            Long userId = extractUserId(authHeader);
            Boolean enabled = body.get("enabled");

            if (enabled == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Missing 'enabled' field"));
            }

            CategoryReminderDTO reminder = reminderService.toggleReminder(userId, categoryId, enabled);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "enabled", enabled,
                    "reminder", reminder
            ));
        } catch (Exception e) {
            log.error("❌ toggleReminder error: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==================== DELETE ====================

    /**
     * DELETE /api/category-reminder/{categoryId}
     * Xóa reminder
     */
    @DeleteMapping("/{categoryId}")
    public ResponseEntity<?> deleteReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId) {
        try {
            Long userId = extractUserId(authHeader);
            reminderService.deleteReminder(userId, categoryId);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Đã xóa nhắc nhở"
            ));
        } catch (Exception e) {
            log.error("❌ deleteReminder error: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==================== HELPER ====================

    private Long extractUserId(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Missing or invalid Authorization header");
        }
        String token = authHeader.substring(7);
        return jwtUtil.getUserIdFromToken(token);
    }
}