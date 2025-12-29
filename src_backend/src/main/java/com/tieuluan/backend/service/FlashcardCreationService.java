package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.FlashcardRepository;
import com.tieuluan.backend.repository.UserRepository;
import com.tieuluan.backend.service.DictionaryService.DictionaryLookupResult;
import com.tieuluan.backend.service.ImageSuggestionService.ImageSuggestionResult;
import com.tieuluan.backend.service.ImageSuggestionService.ImageInfo;
import com.tieuluan.backend.service.CategorySuggestionService.CategorySuggestionResult;
import com.tieuluan.backend.service.CategorySuggestionService.CategorySuggestion;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * Service tạo Flashcard mới với flow:
 * 1. Tra từ điển offline (DictionaryService)
 * 2. Gợi ý 5 hình ảnh (ImageSuggestionService)
 * 3. Gợi ý category bằng AI (CategorySuggestionService)
 * 4. Tạo audio TTS (GoogleCloudStorageService)
 * 5. Lưu flashcard
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FlashcardCreationService {

    private final DictionaryService dictionaryService;
    private final ImageSuggestionService imageSuggestionService;
    private final CategorySuggestionService categorySuggestionService;
    private final GoogleCloudStorageService gcsService;
    private final FlashcardRepository flashcardRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    /**
     * ========================================
     * STEP 1: Lookup từ điển + gợi ý ảnh
     * ========================================
     * Gọi khi user nhập từ vựng
     */
    public FlashcardPreviewResult previewFlashcard(String term) {
        log.info("📝 Preview flashcard for term: '{}'", term);

        FlashcardPreviewResult result = new FlashcardPreviewResult();
        result.setTerm(term);

        try {
            // 1. Tra từ điển
            DictionaryLookupResult dictResult = dictionaryService.lookup(term);
            result.setDictionaryResult(dictResult);

            if (dictResult.isFound()) {
                log.info("✅ Found in dictionary: {}", term);
            } else {
                log.warn("⚠️ Not found in dictionary: {}", term);
            }

            // 2. Gợi ý hình ảnh
            ImageSuggestionResult imageResult = imageSuggestionService.suggestImages(term, 5);
            result.setImageSuggestions(imageResult.getImages());

            result.setSuccess(true);
            result.setMessage(dictResult.isFound()
                    ? "Đã tìm thấy từ trong từ điển"
                    : "Từ không có trong từ điển, bạn có thể nhập thủ công");

            return result;

        } catch (Exception e) {
            log.error("❌ Error previewing flashcard: {}", e.getMessage(), e);
            result.setSuccess(false);
            result.setMessage("Lỗi: " + e.getMessage());
            return result;
        }
    }

    /**
     * ========================================
     * STEP 2: Gợi ý category
     * ========================================
     * Gọi sau khi user xác nhận thông tin từ
     */
    public CategorySuggestionResult suggestCategories(String term, String meaning, String partOfSpeech) {
        log.info("🏷️ Suggesting categories for: '{}'", term);
        return categorySuggestionService.suggestCategories(term, meaning, partOfSpeech);
    }

    /**
     * ========================================
     * STEP 3: Tạo và lưu flashcard
     * ========================================
     * Gọi khi user xác nhận tất cả và bấm Lưu
     */
    @Transactional
    public FlashcardCreateResult createFlashcard(FlashcardCreateRequest request) {
        log.info("💾 Creating flashcard for term: '{}'", request.getTerm());

        FlashcardCreateResult result = new FlashcardCreateResult();

        try {
            // 1. Validate category
            Category category = null;
            if (request.getCategoryId() != null) {
                category = categoryRepository.findById(request.getCategoryId())
                        .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

                // Check ownership
                Long userId = getCurrentUserId();
                if (!canUserAccessCategory(category, userId)) {
                    result.setSuccess(false);
                    result.setMessage("Bạn không có quyền sử dụng category này");
                    return result;
                }
            }

            // 2. Generate TTS nếu cần
            String ttsUrl = null;
            if (request.isGenerateAudio()) {
                ttsUrl = gcsService.createAndUploadAudio(request.getTerm(), "en-US");
                log.info("✅ TTS generated: {}", ttsUrl);
            }

            // 3. Build meaning text
            String meaning = buildMeaning(request);

            // 4. Create flashcard
            Flashcard flashcard = new Flashcard();
            flashcard.setTerm(request.getTerm());
            flashcard.setPartOfSpeech(request.getPartOfSpeech());
            flashcard.setPhonetic(request.getPhonetic());
            flashcard.setMeaning(meaning);
            flashcard.setImageUrl(request.getSelectedImageUrl());
            flashcard.setTtsUrl(ttsUrl);
            flashcard.setCategory(category);

            // 5. Save
            Flashcard saved = flashcardRepository.save(flashcard);

            result.setSuccess(true);
            result.setMessage("Flashcard đã được tạo thành công!");
            result.setFlashcardId(saved.getId());
            result.setFlashcard(saved);

            log.info("✅ Flashcard saved with ID: {}", saved.getId());
            return result;

        } catch (Exception e) {
            log.error("❌ Error creating flashcard: {}", e.getMessage(), e);
            result.setSuccess(false);
            result.setMessage("Lỗi khi tạo flashcard: " + e.getMessage());
            return result;
        }
    }

    /**
     * ========================================
     * BATCH: Tạo nhiều flashcard từ danh sách
     * ========================================
     * Dùng cho OCR và PDF
     */
    @Transactional
    public BatchCreateResult batchCreateFlashcards(List<FlashcardCreateRequest> requests) {
        log.info("📚 Batch creating {} flashcards", requests.size());

        BatchCreateResult result = new BatchCreateResult();
        result.setTotalRequested(requests.size());
        result.setResults(new ArrayList<>());

        int successCount = 0;
        int failCount = 0;

        for (FlashcardCreateRequest request : requests) {
            FlashcardCreateResult createResult = createFlashcard(request);
            result.getResults().add(createResult);

            if (createResult.isSuccess()) {
                successCount++;
            } else {
                failCount++;
            }

            // Delay để tránh rate limit
            try {
                Thread.sleep(300);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        result.setSuccessCount(successCount);
        result.setFailCount(failCount);
        result.setSuccess(failCount == 0);
        result.setMessage(String.format("Đã tạo %d/%d flashcards thành công",
                successCount, requests.size()));

        log.info("✅ Batch complete: {} success, {} failed", successCount, failCount);
        return result;
    }

    // ================== Helper Methods ==================

    private String buildMeaning(FlashcardCreateRequest request) {
        StringBuilder meaning = new StringBuilder();

        // Vietnamese meaning
        if (request.getMeaning() != null && !request.getMeaning().isEmpty()) {
            meaning.append(request.getMeaning());
        }

        // English definition
        if (request.getDefinition() != null && !request.getDefinition().isEmpty()) {
            if (meaning.length() > 0) {
                meaning.append("\n\n");
            }
            meaning.append("📖 ").append(request.getDefinition());
        }

        // Example
        if (request.getExample() != null && !request.getExample().isEmpty()) {
            meaning.append("\n\n📝 Example: ").append(request.getExample());
        }

        return meaning.toString();
    }

    private Long getCurrentUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String email = auth.getName();
            User user = userRepository.findByEmail(email).orElse(null);
            return user != null ? user.getId() : null;
        } catch (Exception e) {
            return null;
        }
    }

    private boolean canUserAccessCategory(Category category, Long userId) {
        if (category.isSystemCategory()) return true;
        if (category.isPublic()) return true;
        if (category.getOwnerUserId() != null && category.getOwnerUserId().equals(userId)) return true;
        return false;
    }

    // ================== DTOs ==================

    @Data
    public static class FlashcardPreviewResult {
        private boolean success;
        private String message;
        private String term;
        private DictionaryLookupResult dictionaryResult;
        private List<ImageInfo> imageSuggestions;
    }

    @Data
    public static class FlashcardCreateRequest {
        private String term;
        private String partOfSpeech;
        private String phonetic;
        private String meaning;          // Vietnamese
        private String definition;       // English
        private String example;
        private String selectedImageUrl;
        private Long categoryId;
        private boolean generateAudio = true;
    }

    @Data
    public static class FlashcardCreateResult {
        private boolean success;
        private String message;
        private Long flashcardId;
        private Flashcard flashcard;
    }

    @Data
    public static class BatchCreateResult {
        private boolean success;
        private String message;
        private int totalRequested;
        private int successCount;
        private int failCount;
        private List<FlashcardCreateResult> results;
    }
}