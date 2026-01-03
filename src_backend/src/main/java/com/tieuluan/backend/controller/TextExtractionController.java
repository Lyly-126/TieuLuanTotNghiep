package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.TextExtractionService;
import com.tieuluan.backend.service.TextExtractionService.*;
import com.tieuluan.backend.service.FlashcardCreationService;
import com.tieuluan.backend.service.FlashcardCreationService.*;
import com.tieuluan.backend.service.CategorySuggestionService;
import com.tieuluan.backend.service.CategorySuggestionService.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Controller cho tính năng OCR và PDF extraction
 *
 * API Endpoints:
 *
 * POST /api/text-extraction/ocr          - Upload ảnh và trích xuất từ vựng
 * POST /api/text-extraction/pdf          - Upload PDF và trích xuất từ vựng
 * POST /api/text-extraction/preview      - Preview danh sách từ đã chọn
 * POST /api/text-extraction/create-batch - Tạo flashcard hàng loạt từ danh sách đã chọn
 * POST /api/text-extraction/suggest-category - Gợi ý category cho batch từ vựng
 */
@Slf4j
@RestController
@RequestMapping("/api/text-extraction")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class TextExtractionController {

    private final TextExtractionService textExtractionService;
    private final FlashcardCreationService flashcardCreationService;
    private final CategorySuggestionService categorySuggestionService;

    // ==================== OCR - EXTRACT FROM IMAGE ====================

    /**
     * POST /api/text-extraction/ocr
     *
     * Upload ảnh và trích xuất từ vựng tiếng Anh
     *
     * Request: multipart/form-data với field "image"
     * Response: TextExtractionResult với danh sách từ vựng
     */
    @PostMapping(value = "/ocr", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<TextExtractionResult> extractFromImage(
            @RequestParam("image") MultipartFile imageFile) {

        log.info("📷 OCR request received: {}", imageFile.getOriginalFilename());

        TextExtractionResult result = textExtractionService.extractFromImage(imageFile);

        if (result.isSuccess()) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.badRequest().body(result);
        }
    }

    // ==================== PDF EXTRACTION ====================

    /**
     * POST /api/text-extraction/pdf
     *
     * Upload PDF và trích xuất từ vựng tiếng Anh
     *
     * Request: multipart/form-data với field "file"
     * Response: TextExtractionResult với danh sách từ vựng
     */
    @PostMapping(value = "/pdf", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<TextExtractionResult> extractFromPDF(
            @RequestParam("file") MultipartFile pdfFile) {

        log.info("📄 PDF extraction request received: {}", pdfFile.getOriginalFilename());

        TextExtractionResult result = textExtractionService.extractFromPDF(pdfFile);

        if (result.isSuccess()) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.badRequest().body(result);
        }
    }

    // ==================== PREVIEW SELECTED WORDS ====================

    /**
     * POST /api/text-extraction/preview
     *
     * Preview chi tiết cho danh sách từ đã chọn
     * Tra từ điển và lấy thông tin đầy đủ
     *
     * Request: { "words": ["apple", "banana", "computer"] }
     * Response: BatchPreviewResult với thông tin chi tiết từng từ
     */
    @PostMapping("/preview")
    public ResponseEntity<BatchPreviewResult> previewWords(
            @RequestBody PreviewWordsRequest request) {

        log.info("🔍 Preview request for {} words", request.getWords().size());

        BatchPreviewResult result = textExtractionService.batchPreviewWords(request.getWords());
        return ResponseEntity.ok(result);
    }

    // ==================== SUGGEST CATEGORY FOR BATCH ====================

    /**
     * POST /api/text-extraction/suggest-category
     *
     * Gợi ý category phù hợp cho một batch từ vựng
     * AI sẽ phân tích chủ đề chung của các từ
     *
     * Request: { "words": [{ "word": "apple", "meaning": "táo" }, ...] }
     * Response: BatchCategorySuggestionResult
     */
    @PostMapping("/suggest-category")
    public ResponseEntity<BatchCategorySuggestionResult> suggestCategoryForBatch(
            @RequestBody SuggestCategoryBatchRequest request) {

        log.info("🏷️ Category suggestion request for {} words", request.getWords().size());

        try {
            // Lấy từ đầu tiên có meaning để phân tích
            String representativeWord = request.getWords().stream()
                    .filter(w -> w.getMeaning() != null && !w.getMeaning().isEmpty())
                    .map(WordInfo::getWord)
                    .findFirst()
                    .orElse(request.getWords().isEmpty() ? "" : request.getWords().get(0).getWord());

            String representativeMeaning = request.getWords().stream()
                    .filter(w -> w.getMeaning() != null && !w.getMeaning().isEmpty())
                    .map(WordInfo::getMeaning)
                    .findFirst()
                    .orElse("");

            String representativePartOfSpeech = request.getWords().stream()
                    .filter(w -> w.getPartOfSpeech() != null && !w.getPartOfSpeech().isEmpty())
                    .map(WordInfo::getPartOfSpeech)
                    .findFirst()
                    .orElse(null);

            // Gọi AI suggestion (sử dụng method có sẵn trong CategorySuggestionService)
            CategorySuggestionResult aiResult = categorySuggestionService.suggestCategories(
                    representativeWord,
                    representativeMeaning,
                    representativePartOfSpeech
            );

            // Wrap result
            BatchCategorySuggestionResult result = new BatchCategorySuggestionResult();
            result.setSuccess(aiResult.isSuccess());
            result.setMessage(aiResult.getMessage());
            result.setSuggestions(aiResult.getSuggestions());
            result.setUserCategories(new ArrayList<>()); // Empty list nếu không có
            result.setTotalWordsAnalyzed(request.getWords().size());

            return ResponseEntity.ok(result);

        } catch (Exception e) {
            log.error("❌ Category suggestion failed: {}", e.getMessage(), e);
            BatchCategorySuggestionResult errorResult = new BatchCategorySuggestionResult();
            errorResult.setSuccess(false);
            errorResult.setMessage("Lỗi gợi ý category: " + e.getMessage());
            errorResult.setSuggestions(new ArrayList<>());
            errorResult.setUserCategories(new ArrayList<>());
            return ResponseEntity.badRequest().body(errorResult);
        }
    }

    // ==================== CREATE FLASHCARDS BATCH ====================

    /**
     * POST /api/text-extraction/create-batch
     *
     * Tạo flashcard hàng loạt từ danh sách từ đã chọn
     *
     * Request: BatchFlashcardCreateRequest
     * Response: BatchCreateResult
     */
    @PostMapping("/create-batch")
    public ResponseEntity<BatchCreateResult> createFlashcardsBatch(
            @RequestBody BatchFlashcardCreateRequest request) {

        log.info("📚 Batch create request for {} words, category: {}",
                request.getWords().size(), request.getCategoryId());

        try {
            // Convert to FlashcardCreateRequest list
            List<FlashcardCreateRequest> createRequests = request.getWords().stream()
                    .map(word -> {
                        FlashcardCreateRequest fcRequest = new FlashcardCreateRequest();
                        fcRequest.setWord(word.getWord());
                        fcRequest.setPartOfSpeech(word.getPartOfSpeech());
                        fcRequest.setPartOfSpeechVi(word.getPartOfSpeechVi());
                        fcRequest.setPhonetic(word.getPhonetic());
                        fcRequest.setMeaning(word.getMeaning());
                        fcRequest.setDefinition(word.getDefinition());
                        fcRequest.setCategoryId(request.getCategoryId());
                        fcRequest.setGenerateAudio(request.isGenerateAudio());
                        return fcRequest;
                    })
                    .collect(Collectors.toList());

            // Call batch create
            BatchCreateResult result = flashcardCreationService.batchCreateFlashcards(createRequests);

            return ResponseEntity.ok(result);

        } catch (Exception e) {
            log.error("❌ Batch create failed: {}", e.getMessage(), e);
            BatchCreateResult errorResult = new BatchCreateResult();
            errorResult.setSuccess(false);
            errorResult.setMessage("Lỗi tạo flashcard: " + e.getMessage());
            errorResult.setResults(new ArrayList<>());
            return ResponseEntity.badRequest().body(errorResult);
        }
    }

    // ==================== DTOs ====================

    @Data
    public static class PreviewWordsRequest {
        private List<String> words;
    }

    @Data
    public static class WordInfo {
        private String word;
        private String partOfSpeech;
        private String partOfSpeechVi;
        private String meaning;
        private String phonetic;
        private String definition;
    }

    @Data
    public static class SuggestCategoryBatchRequest {
        private List<WordInfo> words;
    }

    @Data
    public static class BatchCategorySuggestionResult {
        private boolean success;
        private String message;
        private int totalWordsAnalyzed;
        private List<CategorySuggestion> suggestions;
        private List<CategorySuggestion> userCategories;
    }

    @Data
    public static class BatchFlashcardCreateRequest {
        private List<WordInfo> words;
        private Long categoryId;
        private boolean generateAudio = true;
    }
}