package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.ImageSuggestionService;
import com.tieuluan.backend.service.ImageSuggestionService.ImageSuggestionResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller cho Image Suggestion API
 *
 * Endpoints:
 * - GET /api/images/suggest?word=apple        → Gợi ý 5 ảnh
 * - GET /api/images/suggest?word=apple&count=3 → Gợi ý 3 ảnh
 * - GET /api/images/status                    → Kiểm tra trạng thái service
 */
@Slf4j
@RestController
@RequestMapping("/api/images")
@RequiredArgsConstructor
public class ImageSuggestionController {

    private final ImageSuggestionService imageSuggestionService;

    /**
     * Gợi ý hình ảnh cho từ vựng
     * GET /api/images/suggest?word=apple
     * GET /api/images/suggest?word=apple&count=3
     */
    @GetMapping("/suggest")
    public ResponseEntity<ImageSuggestionResult> suggestImages(
            @RequestParam String word,
            @RequestParam(defaultValue = "5") int count) {

        log.info("🖼️ API: Suggest {} images for '{}'", count, word);

        // Giới hạn số lượng ảnh từ 1-10
        count = Math.max(1, Math.min(10, count));

        ImageSuggestionResult result = imageSuggestionService.suggestImages(word, count);
        return ResponseEntity.ok(result);
    }

    /**
     * Kiểm tra trạng thái service
     * GET /api/images/status
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        log.info("📊 API: Check image service status");

        boolean configured = imageSuggestionService.isConfigured();

        return ResponseEntity.ok(Map.of(
                "service", "ImageSuggestionService",
                "provider", "Pexels",
                "configured", configured,
                "status", configured ? "READY" : "NOT_CONFIGURED"
        ));
    }
}