package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.CategorySuggestionService;
import com.tieuluan.backend.service.CategorySuggestionService.CategorySuggestionResult;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller cho Category Suggestion API
 *
 * ✅ Service tự động lấy userId từ SecurityContext
 * ✅ Chỉ gợi ý categories của user (không lấy system)
 *
 * Endpoints:
 * - POST /api/categories/suggest   → Gợi ý categories cho từ vựng
 * - GET  /api/categories/suggest   → Gợi ý categories (simple)
 */
@Slf4j
@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategorySuggestionController {

    private final CategorySuggestionService categorySuggestionService;

    /**
     * Gợi ý categories phù hợp cho từ vựng
     * POST /api/categories/suggest
     * Body: { "word": "apple", "meaning": "quả táo", "partOfSpeech": "noun" }
     */
    @PostMapping("/suggest")
    public ResponseEntity<CategorySuggestionResult> suggestCategories(
            @RequestBody SuggestCategoryRequest request) {

        log.info("🏷️ API: Suggest categories for word '{}'", request.getWord());

        // ✅ CHỈ TRUYỀN 3 THAM SỐ - Service tự lấy userId từ SecurityContext
        CategorySuggestionResult result = categorySuggestionService.suggestCategories(
                request.getWord(),
                request.getMeaning(),
                request.getPartOfSpeech()
        );

        return ResponseEntity.ok(result);
    }

    /**
     * Gợi ý categories qua GET (simple)
     * GET /api/categories/suggest?word=apple
     */
    @GetMapping("/suggest")
    public ResponseEntity<CategorySuggestionResult> suggestCategoriesGet(
            @RequestParam String word,
            @RequestParam(required = false) String meaning,
            @RequestParam(required = false) String partOfSpeech) {

        log.info("🏷️ API: Suggest categories for word '{}' (GET)", word);

        // ✅ CHỈ TRUYỀN 3 THAM SỐ - Service tự lấy userId từ SecurityContext
        CategorySuggestionResult result = categorySuggestionService.suggestCategories(
                word, meaning, partOfSpeech
        );

        return ResponseEntity.ok(result);
    }

    // ================== Request DTO ==================

    @Data
    public static class SuggestCategoryRequest {
        private String word;
        private String meaning;
        private String partOfSpeech;
    }
}