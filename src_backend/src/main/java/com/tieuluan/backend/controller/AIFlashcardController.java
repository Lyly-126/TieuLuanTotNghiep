package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.AIFlashcardService;
import com.tieuluan.backend.service.AIFlashcardService.CreateFlashcardRequest;
import com.tieuluan.backend.service.AIFlashcardService.CreateFlashcardResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * REST API Controller cho AI-powered flashcard generation
 */
@Slf4j
@RestController
@RequestMapping("/api/flashcards/ai")
@RequiredArgsConstructor
public class AIFlashcardController {

    private final AIFlashcardService aiFlashcardService;

    /**
     * Tạo flashcard tự động bằng AI từ một từ vựng
     *
     * POST /api/flashcards/ai/generate
     * Body: {
     *   "term": "bank",
     *   "categoryId": 1,
     *   "generateImage": true,
     *   "generateAudio": true
     * }
     *
     * @param request Request chứa term và options
     * @return Response với flashcard hoàn chỉnh và status từng bước
     */
    @PostMapping("/generate")
//    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<CreateFlashcardResponse> generateFlashcard(
            @RequestBody CreateFlashcardRequest request) {

        try {
            log.info("📨 Received AI flashcard generation request for: {}", request.term);

            CreateFlashcardResponse response = aiFlashcardService.generateFlashcard(request);

            if (response.success) {
                log.info("✅ AI flashcard generated successfully for: {}", request.term);
                return ResponseEntity.ok(response);
            } else {
                log.error("❌ AI flashcard generation failed: {}", response.message);
                return ResponseEntity.badRequest().body(response);
            }

        } catch (Exception e) {
            log.error("❌ Unexpected error in AI flashcard generation: {}", e.getMessage());
            CreateFlashcardResponse errorResponse = new CreateFlashcardResponse();
            errorResponse.success = false;
            errorResponse.message = "Internal server error: " + e.getMessage();
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }

    /**
     * Batch generate flashcards từ nhiều từ vựng
     *
     * POST /api/flashcards/ai/batch
     * Body: {
     *   "terms": ["bank", "account", "deposit"],
     *   "categoryId": 1
     * }
     */
    @PostMapping("/batch")
//    @PreAuthorize("hasAnyRole('USER', 'ADMIN')")
    public ResponseEntity<CreateFlashcardResponse[]> batchGenerateFlashcards(
            @RequestBody Map<String, Object> payload) {

        try {
            @SuppressWarnings("unchecked")
            java.util.List<String> termsList = (java.util.List<String>) payload.get("terms");
            String[] terms = termsList.toArray(new String[0]);

            Long categoryId = payload.get("categoryId") != null
                    ? Long.valueOf(payload.get("categoryId").toString())
                    : null;

            log.info("📨 Received batch AI flashcard generation request for {} terms", terms.length);

            CreateFlashcardResponse[] responses = aiFlashcardService.batchGenerateFlashcards(terms, categoryId);

            long successCount = java.util.Arrays.stream(responses)
                    .filter(r -> r.success)
                    .count();

            log.info("✅ Batch generation completed: {}/{} successful", successCount, terms.length);

            return ResponseEntity.ok(responses);

        } catch (Exception e) {
            log.error("❌ Error in batch flashcard generation: {}", e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Kiểm tra status của các AI services
     *
     * GET /api/flashcards/ai/status
     *
     * @return Status của từng service (configured hay chưa)
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> checkStatus() {
        try {
            Map<String, Boolean> servicesStatus = aiFlashcardService.checkServicesStatus();

            boolean allConfigured = servicesStatus.values().stream()
                    .allMatch(status -> status);

            Map<String, Object> response = new java.util.HashMap<>();
            response.put("ready", allConfigured);
            response.put("services", servicesStatus);

            if (!allConfigured) {
                response.put("message", "Some services are not configured. Please check API keys in application.properties");
            } else {
                response.put("message", "All services ready");
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ Error checking services status: {}", e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "service", "AI Flashcard Generation"
        ));
    }


}