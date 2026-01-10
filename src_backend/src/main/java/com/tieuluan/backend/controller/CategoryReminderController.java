package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.CategoryReminderDTO;
import com.tieuluan.backend.service.CategoryReminderService;
import com.tieuluan.backend.service.FirebaseNotificationService;
import com.tieuluan.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/category-reminders")
@RequiredArgsConstructor
@Slf4j
public class CategoryReminderController {

    private final CategoryReminderService reminderService;
    private final FirebaseNotificationService firebaseService;
    private final JwtUtil jwtUtil;

    /**
     * GET /api/category-reminders
     * Lấy tất cả reminders của user
     */
    @GetMapping
    public ResponseEntity<?> getAllReminders(@RequestHeader("Authorization") String authHeader) {
        try {
            Long userId = extractUserId(authHeader);
            List<CategoryReminderDTO> reminders = reminderService.getUserReminders(userId);
            return ResponseEntity.ok(reminders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/category-reminders/weekly-schedule
     * Lấy thời khóa biểu tuần
     */
    @GetMapping("/weekly-schedule")
    public ResponseEntity<?> getWeeklySchedule(@RequestHeader("Authorization") String authHeader) {
        try {
            Long userId = extractUserId(authHeader);
            Map<Integer, List<CategoryReminderDTO>> schedule = reminderService.getWeeklySchedule(userId);
            return ResponseEntity.ok(schedule);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/category-reminders/category/{categoryId}
     * Lấy reminder của category
     */
    @GetMapping("/category/{categoryId}")
    public ResponseEntity<?> getCategoryReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId) {
        try {
            Long userId = extractUserId(authHeader);
            CategoryReminderDTO reminder = reminderService.getCategoryReminder(userId, categoryId);
            return ResponseEntity.ok(reminder);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * PUT /api/category-reminders/category/{categoryId}
     * Tạo/cập nhật reminder (kèm fcmToken)
     */
    @PutMapping("/category/{categoryId}")
    public ResponseEntity<?> upsertReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId,
            @RequestBody Map<String, Object> body) {
        try {
            Long userId = extractUserId(authHeader);

            Integer hour = body.get("hour") != null ? ((Number) body.get("hour")).intValue() : null;
            Integer minute = body.get("minute") != null ? ((Number) body.get("minute")).intValue() : null;
            String daysOfWeek = (String) body.get("daysOfWeek");
            Boolean isEnabled = (Boolean) body.get("isEnabled");
            String customMessage = (String) body.get("customMessage");
            String fcmToken = (String) body.get("fcmToken");

            CategoryReminderDTO result = reminderService.upsertReminder(
                    userId, categoryId, hour, minute, daysOfWeek, isEnabled, customMessage, fcmToken);

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/category-reminders/category/{categoryId}/toggle
     * Bật/tắt reminder (kèm fcmToken)
     */
    @PostMapping("/category/{categoryId}/toggle")
    public ResponseEntity<?> toggleReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId,
            @RequestBody Map<String, Object> body) {
        try {
            Long userId = extractUserId(authHeader);
            Boolean enabled = (Boolean) body.get("enabled");
            String fcmToken = (String) body.get("fcmToken");

            if (enabled == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Missing 'enabled'"));
            }

            CategoryReminderDTO result = reminderService.toggleReminder(userId, categoryId, enabled, fcmToken);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * DELETE /api/category-reminders/category/{categoryId}
     * Xóa reminder
     */
    @DeleteMapping("/category/{categoryId}")
    public ResponseEntity<?> deleteReminder(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long categoryId) {
        try {
            Long userId = extractUserId(authHeader);
            reminderService.deleteReminder(userId, categoryId);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==================== FCM TOKEN ====================

    /**
     * POST /api/category-reminders/fcm-token
     * Cập nhật fcmToken cho tất cả reminders của user
     */
    @PostMapping("/fcm-token")
    public ResponseEntity<?> updateFcmToken(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Map<String, String> body) {
        try {
            Long userId = extractUserId(authHeader);
            String fcmToken = body.get("fcmToken");
            if (fcmToken == null || fcmToken.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Missing fcmToken"));
            }
            reminderService.updateFcmToken(userId, fcmToken);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * DELETE /api/category-reminders/fcm-token
     * Xóa fcmToken (logout)
     */
    @DeleteMapping("/fcm-token")
    public ResponseEntity<?> clearFcmToken(@RequestHeader("Authorization") String authHeader) {
        try {
            Long userId = extractUserId(authHeader);
            reminderService.clearFcmToken(userId);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/category-reminders/test-notification
     * Test notification
     */
    @PostMapping("/test-notification")
    public ResponseEntity<?> sendTestNotification(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody(required = false) Map<String, String> body) {
        try {
            String fcmToken = body != null ? body.get("fcmToken") : null;
            if (fcmToken == null || fcmToken.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Missing fcmToken"));
            }
            boolean sent = firebaseService.sendTestNotification(fcmToken);
            return ResponseEntity.ok(Map.of("success", sent));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    private Long extractUserId(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Invalid Authorization header");
        }
        String token = authHeader.substring(7);
        return jwtUtil.getUserIdFromToken(token);
    }
}