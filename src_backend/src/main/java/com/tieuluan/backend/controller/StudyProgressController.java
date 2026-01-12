package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.*;
import com.tieuluan.backend.model.StudyProgress;
import com.tieuluan.backend.service.StudyProgressService;
import com.tieuluan.backend.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/study")
public class StudyProgressController {

    @Autowired
    private StudyProgressService studyProgressService;

    @Autowired
    private JwtUtil jwtUtil;

    // ==================== PROGRESS APIs ====================

    /**
     * GET /api/study/progress/{categoryId}
     * Lấy tiến trình học của category
     */
    @GetMapping("/progress/{categoryId}")
    public ResponseEntity<?> getCategoryProgress(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Integer categoryId) {
        try {
            Integer userId = extractUserId(authHeader);
            CategoryProgressDTO progress = studyProgressService.getCategoryProgress(userId, categoryId);
            return ResponseEntity.ok(progress);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/study/progress/update
     * Cập nhật tiến trình sau khi trả lời câu hỏi
     */
    @PostMapping("/progress/update")
    public ResponseEntity<?> updateProgress(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody UpdateStudyProgressRequest request) {
        try {
            Integer userId = extractUserId(authHeader);
            StudyProgress progress = studyProgressService.updateProgress(
                    userId,
                    request.getFlashcardId(),
                    request.getCategoryId(),
                    request.getIsCorrect()
            );

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("status", progress.getStatus());
            response.put("correctCount", progress.getCorrectCount());
            response.put("incorrectCount", progress.getIncorrectCount());
            response.put("accuracyRate", progress.getAccuracyRate());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/study/progress/reset/{categoryId}
     * Reset tiến trình học của category
     */
    @PostMapping("/progress/reset/{categoryId}")
    public ResponseEntity<?> resetCategoryProgress(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Integer categoryId) {
        try {
            Integer userId = extractUserId(authHeader);
            studyProgressService.resetCategoryProgress(userId, categoryId);
            return ResponseEntity.ok(Map.of("success", true, "message", "Đã reset tiến trình"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/study/review
     * Lấy các thẻ cần ôn tập
     */
    @GetMapping("/review")
    public ResponseEntity<?> getCardsToReview(
            @RequestHeader("Authorization") String authHeader,
            @RequestParam(required = false) Integer categoryId) {
        try {
            Integer userId = extractUserId(authHeader);
            List<StudyProgress> cards;

            if (categoryId != null) {
                cards = studyProgressService.getCardsToReviewInCategory(userId, categoryId);
            } else {
                cards = studyProgressService.getCardsToReview(userId);
            }

            return ResponseEntity.ok(Map.of(
                    "count", cards.size(),
                    "cards", cards
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==================== STREAK APIs ====================

    /**
     * GET /api/study/streak
     * Lấy thông tin streak của user
     */
    @GetMapping("/streak")
    public ResponseEntity<?> getStreak(@RequestHeader("Authorization") String authHeader) {
        try {
            Integer userId = extractUserId(authHeader);
            StudyStreakDTO streak = studyProgressService.getStreakInfo(userId);
            return ResponseEntity.ok(streak);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/study/weekly
     * Lấy dữ liệu học 7 ngày gần nhất
     */
    @GetMapping("/weekly")
    public ResponseEntity<?> getWeeklyData(@RequestHeader("Authorization") String authHeader) {
        try {
            Integer userId = extractUserId(authHeader);
            List<DailyStudyDTO> weeklyData = studyProgressService.getWeeklyStudyData(userId);
            return ResponseEntity.ok(weeklyData);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // ==================== REMINDER APIs ====================

    /**
     * GET /api/study/reminder
     * Lấy cài đặt nhắc nhở
     */
//    @GetMapping("/reminder")
//    public ResponseEntity<?> getReminderSettings(@RequestHeader("Authorization") String authHeader) {
//        try {
//            Integer userId = extractUserId(authHeader);
//            StudyReminderDTO reminder = studyProgressService.getReminderSettings(userId);
//            return ResponseEntity.ok(reminder);
//        } catch (Exception e) {
//            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
//        }
//    }

    /**
     * PUT /api/study/reminder
     * Cập nhật cài đặt nhắc nhở
     */
//    @PutMapping("/reminder")
//    public ResponseEntity<?> updateReminderSettings(
//            @RequestHeader("Authorization") String authHeader,
//            @RequestBody UpdateReminderRequest request) {
//        try {
//            Integer userId = extractUserId(authHeader);
//            StudyReminderDTO reminder = studyProgressService.updateReminderSettings(userId, request);
//            return ResponseEntity.ok(reminder);
//        } catch (Exception e) {
//            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
//        }
//    }

    /**
     * POST /api/study/reminder/toggle
     * Bật/tắt nhắc nhở
     */
//    @PostMapping("/reminder/toggle")
//    public ResponseEntity<?> toggleReminder(
//            @RequestHeader("Authorization") String authHeader,
//            @RequestBody Map<String, Boolean> body) {
//        try {
//            Integer userId = extractUserId(authHeader);
//            Boolean enabled = body.get("enabled");
//            if (enabled == null) {
//                return ResponseEntity.badRequest().body(Map.of("error", "Missing 'enabled' field"));
//            }
//            studyProgressService.toggleReminder(userId, enabled);
//            return ResponseEntity.ok(Map.of("success", true, "enabled", enabled));
//        } catch (Exception e) {
//            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
//        }
//    }

    // ==================== HELPER ====================

    private Integer extractUserId(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Missing or invalid Authorization header");
        }
        String token = authHeader.substring(7);
        Long userId = jwtUtil.getUserIdFromToken(token);
        return userId.intValue();
    }
}