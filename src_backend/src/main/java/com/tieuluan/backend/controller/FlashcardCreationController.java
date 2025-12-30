package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.FlashcardCreationService;
import com.tieuluan.backend.service.FlashcardCreationService.*;
import com.tieuluan.backend.service.CategorySuggestionService;
import com.tieuluan.backend.service.CategorySuggestionService.CategorySuggestionResult;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller cho Flashcard Creation Flow
 *
 * FLOW:
 * 1. POST /api/flashcard-creation/preview   → Tra từ điển + gợi ý 6 ảnh
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
    private final CategorySuggestionService categorySuggestionService;

    /**
     * STEP 1: Preview flashcard
     * - Tra từ điển
     * - Gợi ý 6 hình ảnh
     *
     * POST /api/flashcard-creation/preview
     * Body: { "word": "apple" } hoặc { "term": "apple" }
     */
    @PostMapping("/preview")
    public ResponseEntity<FlashcardPreviewResult> previewFlashcard(
            @RequestBody PreviewRequest request) {

        // Hỗ trợ cả "word" và "term"
        String word = request.getWord() != null ? request.getWord() : request.getTerm();
        log.info("🔍 API: Preview flashcard for '{}'", word);

        FlashcardPreviewResult result = flashcardCreationService.previewFlashcard(word);
        return ResponseEntity.ok(result);
    }

    /**
     * GET version của preview
     * GET /api/flashcard-creation/preview?word=apple
     * GET /api/flashcard-creation/preview?term=apple
     */
    @GetMapping("/preview")
    public ResponseEntity<FlashcardPreviewResult> previewFlashcardGet(
            @RequestParam(required = false) String word,
            @RequestParam(required = false) String term) {

        // Hỗ trợ cả "word" và "term"
        String actualWord = word != null ? word : term;
        log.info("🔍 API: Preview flashcard for '{}' (GET)", actualWord);

        FlashcardPreviewResult result = flashcardCreationService.previewFlashcard(actualWord);
        return ResponseEntity.ok(result);
    }

    /**
     * STEP 2: Gợi ý category
     * ✅ Service tự động lấy userId từ SecurityContext
     *
     * POST /api/flashcard-creation/suggest-category
     * Body: { "word": "apple", "meaning": "quả táo", "partOfSpeech": "noun" }
     */
    @PostMapping("/suggest-category")
    public ResponseEntity<CategorySuggestionResult> suggestCategory(
            @RequestBody SuggestCategoryRequest request) {

        // Hỗ trợ cả "word" và "term"
        String word = request.getWord() != null ? request.getWord() : request.getTerm();
        log.info("🏷️ API: Suggest category for '{}'", word);

        // ✅ CHỈ TRUYỀN 3 THAM SỐ - Service tự lấy userId
        CategorySuggestionResult result = categorySuggestionService.suggestCategories(
                word,
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

        // ✅ Đổi từ getTerm() thành getWord()
        log.info("💾 API: Create flashcard for '{}'", request.getWord());

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

        log.info("🔍 API: Batch preview {} terms", request.getTerms().size());

        List<FlashcardPreviewResult> results = request.getTerms().stream()
                .map(flashcardCreationService::previewFlashcard)
                .toList();

        return ResponseEntity.ok(results);
    }

    // ================== Request DTOs ==================

    @Data
    public static class PreviewRequest {
        private String word;  // Hỗ trợ Flutter mới
        private String term;  // Backward compatible
    }

    @Data
    public static class SuggestCategoryRequest {
        private String word;  // Hỗ trợ Flutter mới
        private String term;  // Backward compatible
        private String meaning;
        private String partOfSpeech;
    }

    @Data
    public static class BatchPreviewRequest {
        private List<String> terms;
    }
}