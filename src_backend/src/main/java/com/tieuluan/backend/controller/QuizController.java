package com.tieuluan.backend.controller;

import com.tieuluan.backend.dto.QuizDTO.*;
import com.tieuluan.backend.model.QuizResult;
import com.tieuluan.backend.service.QuizService;
import com.tieuluan.backend.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 🎯 QuizController - REST API cho chức năng Quiz/Test
 *
 * Endpoints:
 * - POST /api/quiz/generate         - Sinh quiz mới
 * - POST /api/quiz/submit           - Submit và tính điểm quiz
 * - GET  /api/quiz/stats            - Thống kê quiz của user
 * - GET  /api/quiz/stats/{categoryId} - Thống kê quiz cho category
 * - GET  /api/quiz/history          - Lịch sử quiz
 * - GET  /api/quiz/result/{id}      - Chi tiết một kết quả quiz
 */
@RestController
@RequestMapping("/api/quiz")
@CrossOrigin(origins = "*")
public class QuizController {

    @Autowired
    private QuizService quizService;

    @Autowired
    private JwtUtil jwtUtil;

    // ==================== GENERATE QUIZ ====================

    /**
     * POST /api/quiz/generate
     * Sinh quiz mới cho user
     *
     * Request body:
     * {
     *   "categoryId": 1,
     *   "quizType": "MIXED",           // Optional: MIXED, MULTIPLE_CHOICE, FILL_BLANK, LISTENING, etc.
     *   "difficulty": "AUTO",          // Optional: AUTO (theo tuổi), KIDS, TEEN, ADULT
     *   "numberOfQuestions": 10,       // Optional: 5-50
     *   "skillFocus": ["LISTENING", "READING", "WRITING"], // Optional
     *   "includeImages": true,         // Optional
     *   "timeLimitSeconds": 600        // Optional: 0 = không giới hạn
     * }
     */
    @PostMapping("/generate")
    public ResponseEntity<?> generateQuiz(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody GenerateQuizRequest request) {
        try {
            Integer userId = extractUserId(authHeader);
            QuizResponse quiz = quizService.generateQuiz(userId, request);
            return ResponseEntity.ok(quiz);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * GET /api/quiz/generate/quick/{categoryId}
     * Sinh quiz nhanh với cài đặt mặc định
     */
    @GetMapping("/generate/quick/{categoryId}")
    public ResponseEntity<?> generateQuickQuiz(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Integer categoryId,
            @RequestParam(defaultValue = "10") Integer questions) {
        try {
            Integer userId = extractUserId(authHeader);

            GenerateQuizRequest request = GenerateQuizRequest.builder()
                    .categoryId(categoryId)
                    .quizType(QuizResult.QuizType.MIXED)
                    .difficulty(QuizResult.DifficultyLevel.AUTO)
                    .numberOfQuestions(questions)
                    .includeImages(true)
                    .build();

            QuizResponse quiz = quizService.generateQuiz(userId, request);
            return ResponseEntity.ok(quiz);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    // ==================== SUBMIT QUIZ ====================

    /**
     * POST /api/quiz/submit
     * Submit quiz và nhận kết quả
     *
     * Request body:
     * {
     *   "categoryId": 1,
     *   "quizType": "MIXED",
     *   "difficulty": "AUTO",
     *   "answers": [
     *     {
     *       "questionIndex": 0,
     *       "flashcardId": 1,
     *       "questionType": "MULTIPLE_CHOICE_EN_VI",
     *       "skillType": "READING",
     *       "userAnswer": "xin chào",
     *       "correctAnswer": "xin chào",
     *       "timeSpentSeconds": 5
     *     },
     *     ...
     *   ],
     *   "totalTimeSeconds": 120
     * }
     */
    @PostMapping("/submit")
    public ResponseEntity<?> submitQuiz(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody SubmitQuizRequest request) {
        try {
            Integer userId = extractUserId(authHeader);
            QuizResultResponse result = quizService.submitQuiz(userId, request);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    // ==================== STATISTICS ====================

    /**
     * GET /api/quiz/stats
     * Lấy thống kê quiz tổng của user
     */
    @GetMapping("/stats")
    public ResponseEntity<?> getUserQuizStats(
            @RequestHeader("Authorization") String authHeader) {
        try {
            Integer userId = extractUserId(authHeader);
            UserQuizStatsDTO stats = quizService.getUserQuizStats(userId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    /**
     * GET /api/quiz/stats/{categoryId}
     * Lấy thống kê quiz cho một category cụ thể
     */
    @GetMapping("/stats/{categoryId}")
    public ResponseEntity<?> getCategoryQuizStats(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Integer categoryId) {
        try {
            Integer userId = extractUserId(authHeader);
            CategoryQuizStatsDTO stats = quizService.getCategoryQuizStats(userId, categoryId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    // ==================== HISTORY ====================

    /**
     * GET /api/quiz/history
     * Lấy lịch sử quiz của user
     */
    @GetMapping("/history")
    public ResponseEntity<?> getQuizHistory(
            @RequestHeader("Authorization") String authHeader,
            @RequestParam(required = false) Integer limit) {
        try {
            Integer userId = extractUserId(authHeader);
            List<QuizHistoryItemDTO> history = quizService.getQuizHistory(userId, limit);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "count", history.size(),
                    "history", history
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "error", e.getMessage()
            ));
        }
    }

    // ==================== QUIZ TYPES INFO ====================

    /**
     * GET /api/quiz/types
     * Lấy danh sách các loại quiz có sẵn
     */
    @GetMapping("/types")
    public ResponseEntity<?> getQuizTypes() {
        return ResponseEntity.ok(Map.of(
                "quizTypes", List.of(
                        Map.of("value", "MIXED", "label", "Hỗn hợp", "description", "Kết hợp nhiều loại câu hỏi", "icon", "🎯"),
                        Map.of("value", "MULTIPLE_CHOICE", "label", "Trắc nghiệm", "description", "Chọn đáp án đúng", "icon", "📝"),
                        Map.of("value", "FILL_BLANK", "label", "Điền khuyết", "description", "Điền từ còn thiếu", "icon", "✏️"),
                        Map.of("value", "LISTENING", "label", "Nghe", "description", "Nghe và chọn/viết đáp án", "icon", "🎧"),
                        Map.of("value", "READING", "label", "Đọc", "description", "Đọc và chọn nghĩa", "icon", "📖"),
                        Map.of("value", "WRITING", "label", "Viết", "description", "Viết từ/câu", "icon", "✏️"),
                        Map.of("value", "IMAGE_WORD", "label", "Nhìn hình", "description", "Nhìn hình đoán từ", "icon", "🖼️"),
                        Map.of("value", "TRUE_FALSE", "label", "Đúng/Sai", "description", "Xác định đúng hay sai", "icon", "✓✗")
                ),
                "difficultyLevels", List.of(
                        Map.of("value", "AUTO", "label", "Tự động", "description", "Theo độ tuổi của bạn", "icon", "🤖"),
                        Map.of("value", "KIDS", "label", "Trẻ em", "description", "Dễ, nhiều hình ảnh", "icon", "👶"),
                        Map.of("value", "TEEN", "label", "Thiếu niên", "description", "Trung bình", "icon", "🧑"),
                        Map.of("value", "ADULT", "label", "Người lớn", "description", "Nâng cao", "icon", "👨")
                ),
                "skillTypes", List.of(
                        Map.of("value", "LISTENING", "label", "Kỹ năng nghe", "icon", "🎧"),
                        Map.of("value", "READING", "label", "Kỹ năng đọc", "icon", "📖"),
                        Map.of("value", "WRITING", "label", "Kỹ năng viết", "icon", "✏️")
                )
        ));
    }

    // ==================== HELPER METHODS ====================

    /**
     * ✅ FIXED: Extract userId from JWT token
     * Đổi từ extractUserId() sang getUserIdFromToken().intValue()
     */
    private Integer extractUserId(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Missing or invalid Authorization header");
        }
        String token = authHeader.substring(7);
        // ✅ FIX: Dùng getUserIdFromToken() thay vì extractUserId()
        return jwtUtil.getUserIdFromToken(token).intValue();
    }
}