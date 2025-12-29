package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.FlashcardCreationService;
import com.tieuluan.backend.service.FlashcardCreationService.*;
import com.tieuluan.backend.service.CategorySuggestionService.CategorySuggestionResult;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller cho Flashcard Creation Flow mới
 *
 * FLOW:
 * 1. POST /api/flashcard-creation/preview   → Tra từ điển + gợi ý ảnh
 * 2. POST /api/flashcard-creation/suggest-category → Gợi ý category bằng AI
 * 3. POST /api/flashcard-creation/create    → Tạo flashcard
 * 4. POST /api/flashcard-creation/batch     → Tạo nhiều flashcard (OCR/PDF)
 */
@Slf4j
@RestController
@RequestMapping("/api/flashcard-creation")
@RequiredArgsConstructor
public class FlashcardCreationController {

    private final FlashcardCreationService flashcardCreationService;

    /**
     * STEP 1: Preview flashcard
     * - Tra từ điển
     * - Gợi ý 5 hình ảnh
     *
     * POST /api/flashcard-creation/preview
     * Body: { "term": "apple" }
     */
    @PostMapping("/preview")
    public ResponseEntity<FlashcardPreviewResult> previewFlashcard(
            @RequestBody PreviewRequest request) {

        log.info("📝 API: Preview flashcard for '{}'", request.getTerm());

        FlashcardPreviewResult result = flashcardCreationService.previewFlashcard(request.getTerm());
        return ResponseEntity.ok(result);
    }

    /**
     * GET version của preview
     * GET /api/flashcard-creation/preview?term=apple
     */
    @GetMapping("/preview")
    public ResponseEntity<FlashcardPreviewResult> previewFlashcardGet(
            @RequestParam String term) {

        log.info("📝 API: Preview flashcard for '{}' (GET)", term);

        FlashcardPreviewResult result = flashcardCreationService.previewFlashcard(term);
        return ResponseEntity.ok(result);
    }

    /**
     * STEP 2: Gợi ý category
     *
     * POST /api/flashcard-creation/suggest-category
     * Body: { "term": "apple", "meaning": "quả táo", "partOfSpeech": "noun" }
     */
    @PostMapping("/suggest-category")
    public ResponseEntity<CategorySuggestionResult> suggestCategory(
            @RequestBody SuggestCategoryRequest request) {

        log.info("🏷️ API: Suggest category for '{}'", request.getTerm());

        CategorySuggestionResult result = flashcardCreationService.suggestCategories(
                request.getTerm(),
                request.getMeaning(),
                request.getPartOfSpeech()
        );

        return ResponseEntity.ok(result);
    }

    /**
     * STEP 3: Tạo flashcard
     *
     * POST /api/flashcard-creation/create
     */
    @PostMapping("/create")
    public ResponseEntity<FlashcardCreateResult> createFlashcard(
            @RequestBody FlashcardCreateRequest request) {

        log.info("💾 API: Create flashcard for '{}'", request.getTerm());

        FlashcardCreateResult result = flashcardCreationService.createFlashcard(request);

        if (result.isSuccess()) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.badRequest().body(result);
        }
    }

    /**
     * BATCH: Tạo nhiều flashcard
     * Dùng cho OCR và PDF
     *
     * POST /api/flashcard-creation/batch
     */
    @PostMapping("/batch")
    public ResponseEntity<BatchCreateResult> batchCreateFlashcards(
            @RequestBody List<FlashcardCreateRequest> requests) {

        log.info("📚 API: Batch create {} flashcards", requests.size());

        if (requests.isEmpty()) {
            BatchCreateResult emptyResult = new BatchCreateResult();
            emptyResult.setSuccess(false);
            emptyResult.setMessage("Danh sách flashcard trống");
            return ResponseEntity.badRequest().body(emptyResult);
        }

        if (requests.size() > 50) {
            BatchCreateResult tooManyResult = new BatchCreateResult();
            tooManyResult.setSuccess(false);
            tooManyResult.setMessage("Tối đa 50 flashcard mỗi lần");
            return ResponseEntity.badRequest().body(tooManyResult);
        }

        BatchCreateResult result = flashcardCreationService.batchCreateFlashcards(requests);
        return ResponseEntity.ok(result);
    }

    /**
     * Preview nhiều từ cùng lúc
     * POST /api/flashcard-creation/batch-preview
     */
    @PostMapping("/batch-preview")
    public ResponseEntity<List<FlashcardPreviewResult>> batchPreview(
            @RequestBody BatchPreviewRequest request) {

        log.info("📝 API: Batch preview {} terms", request.getTerms().size());

        List<FlashcardPreviewResult> results = request.getTerms().stream()
                .map(flashcardCreationService::previewFlashcard)
                .toList();

        return ResponseEntity.ok(results);
    }

    // ================== Request DTOs ==================

    @Data
    public static class PreviewRequest {
        private String term;
    }

    @Data
    public static class SuggestCategoryRequest {
        private String term;
        private String meaning;
        private String partOfSpeech;
    }

    @Data
    public static class BatchPreviewRequest {
        private List<String> terms;
    }
}