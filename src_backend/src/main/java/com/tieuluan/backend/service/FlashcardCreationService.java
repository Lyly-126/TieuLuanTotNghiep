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
 * 2. Gợi ý 6 hình ảnh (ImageSuggestionService)
 * 3. Gợi ý category bằng AI (CategorySuggestionService)
 * 4. Tạo audio TTS (GoogleCloudStorageService)
 * 5. Lưu flashcard
 *
 * ✅ UPDATED: Tự động lấy ảnh đầu tiên nếu không có selectedImageUrl
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
    public FlashcardPreviewResult previewFlashcard(String word) {
        log.info("🔍 Preview flashcard for word: '{}'", word);

        FlashcardPreviewResult result = new FlashcardPreviewResult();
        result.setWord(word);

        try {
            // 1. Tra từ điển
            DictionaryLookupResult dictResult = dictionaryService.lookup(word);
            result.setDictionaryResult(dictResult);

            if (dictResult.isFound()) {
                log.info("✅ Found in dictionary: {}", word);
            } else {
                log.warn("⚠️ Not found in dictionary: {}", word);
            }

            // 2. Gợi ý hình ảnh - 6 ảnh
            ImageSuggestionResult imageResult = imageSuggestionService.suggestImages(word, 6);
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
    public CategorySuggestionResult suggestCategories(String word, String meaning, String partOfSpeech) {
        log.info("🏷️ Suggesting categories for: '{}'", word);
        return categorySuggestionService.suggestCategories(word, meaning, partOfSpeech);
    }

    /**
     * ========================================
     * STEP 3: Tạo và lưu flashcard
     * ========================================
     * Gọi khi user xác nhận tất cả và bấm Lưu
     *
     * ✅ UPDATED: Tự động lấy ảnh đầu tiên nếu không có selectedImageUrl
     */
    @Transactional
    public FlashcardCreateResult createFlashcard(FlashcardCreateRequest request) {
        log.info("💾 Creating flashcard for word: '{}'", request.getWord());

        FlashcardCreateResult result = new FlashcardCreateResult();

        try {
            // 0. Validate word không được null
            if (request.getWord() == null || request.getWord().trim().isEmpty()) {
                result.setSuccess(false);
                result.setMessage("Từ vựng không được để trống");
                return result;
            }

            // ✅ FIX 1: Lấy current user
            User currentUser = getCurrentUser();
            if (currentUser == null) {
                result.setSuccess(false);
                result.setMessage("Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.");
                return result;
            }
            log.info("👤 Creating flashcard for user: {} (ID: {})", currentUser.getEmail(), currentUser.getId());

            // 1. Validate category
            Category category = null;
            if (request.getCategoryId() != null) {
                category = categoryRepository.findById(request.getCategoryId())
                        .orElseThrow(() -> new RuntimeException("Category không tồn tại"));

                // Check ownership
                Long userId = currentUser.getId();
                if (!canUserAccessCategory(category, userId)) {
                    result.setSuccess(false);
                    result.setMessage("Bạn không có quyền sử dụng category này");
                    return result;
                }
            }

            // 2. Generate TTS nếu cần
            String ttsUrl = null;
            if (request.isGenerateAudio() && request.getWord() != null) {
                ttsUrl = gcsService.createAndUploadAudio(request.getWord(), "en-US");
                log.info("✅ TTS generated: {}", ttsUrl);
            }

            // ✅ NEW: Tự động lấy ảnh nếu không có selectedImageUrl
            String imageUrl = request.getSelectedImageUrl();
            if ((imageUrl == null || imageUrl.trim().isEmpty()) && request.getWord() != null) {
                imageUrl = autoSelectFirstImage(request.getWord());
            }

            // 3. Build meaning text
            String meaning = buildMeaning(request);

            // 4. Create flashcard
            Flashcard flashcard = new Flashcard();
            flashcard.setWord(request.getWord());
            flashcard.setPartOfSpeech(request.getPartOfSpeech());

            // ✅ FIX 2: Set partOfSpeechVi
            flashcard.setPartOfSpeechVi(request.getPartOfSpeechVi());
            log.info("📝 Setting partOfSpeechVi: {}", request.getPartOfSpeechVi());

            flashcard.setPhonetic(request.getPhonetic());
            flashcard.setMeaning(meaning);
            flashcard.setImageUrl(imageUrl);  // ✅ Sử dụng imageUrl đã được auto-select
            flashcard.setTtsUrl(ttsUrl);
            flashcard.setCategory(category);

            // ✅ FIX 3: Set user
            flashcard.setUser(currentUser);
            log.info("👤 Setting user: {} (ID: {})", currentUser.getEmail(), currentUser.getId());

            // 5. Save
            Flashcard saved = flashcardRepository.save(flashcard);

            result.setSuccess(true);
            result.setMessage("Flashcard đã được tạo thành công!");
            result.setFlashcardId(saved.getId());
            result.setFlashcard(saved);

            log.info("✅ Flashcard saved with ID: {}, userId: {}, partOfSpeechVi: {}, imageUrl: {}",
                    saved.getId(), saved.getUserId(), saved.getPartOfSpeechVi(),
                    imageUrl != null ? "SET" : "NULL");
            return result;

        } catch (Exception e) {
            log.error("❌ Error creating flashcard: {}", e.getMessage(), e);
            result.setSuccess(false);
            result.setMessage("Lỗi khi tạo flashcard: " + e.getMessage());
            return result;
        }
    }

    /**
     * ✅ NEW: Tự động lấy ảnh đầu tiên từ Pexels cho từ vựng
     *
     * @param word Từ vựng cần tìm ảnh
     * @return URL ảnh đầu tiên hoặc null nếu không tìm thấy
     */
    private String autoSelectFirstImage(String word) {
        try {
            log.info("🖼️ Auto-selecting first image for word: '{}'", word);

            // Gọi API lấy 1 ảnh (chỉ cần ảnh đầu tiên)
            ImageSuggestionResult imageResult = imageSuggestionService.suggestImages(word, 1);

            if (imageResult != null && imageResult.getImages() != null && !imageResult.getImages().isEmpty()) {
                ImageInfo firstImage = imageResult.getImages().get(0);

                // Ưu tiên lấy ảnh medium (kích thước phù hợp cho flashcard)
                String selectedUrl = firstImage.getMedium();
                if (selectedUrl == null || selectedUrl.isEmpty()) {
                    selectedUrl = firstImage.getUrl();
                }
                if (selectedUrl == null || selectedUrl.isEmpty()) {
                    selectedUrl = firstImage.getSmall();
                }
                if (selectedUrl == null || selectedUrl.isEmpty()) {
                    selectedUrl = firstImage.getOriginal();
                }

                log.info("✅ Auto-selected image for '{}': {}", word,
                        selectedUrl != null ? selectedUrl.substring(0, Math.min(50, selectedUrl.length())) + "..." : "null");
                return selectedUrl;
            }

            log.warn("⚠️ No images found for word: '{}'", word);
            return null;

        } catch (Exception e) {
            log.warn("⚠️ Failed to auto-select image for '{}': {}", word, e.getMessage());
            return null;
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

            // Delay để tránh rate limit (đặc biệt khi gọi Pexels API)
            try {
                Thread.sleep(500); // Tăng từ 300ms lên 500ms để tránh rate limit Pexels
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        result.setSuccessCount(successCount);
        result.setFailCount(failCount);
        result.setSuccess(failCount == 0);
        result.setMessage(String.format("Đã tạo %d/%d flashcards thành công (với hình ảnh tự động)",
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

    /**
     * ✅ FIX: Trả về User object thay vì chỉ userId
     */
    private User getCurrentUser() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated()) {
                log.warn("⚠️ No authentication found");
                return null;
            }

            String email = auth.getName();
            log.info("🔍 Looking up user by email: {}", email);

            User user = userRepository.findByEmail(email).orElse(null);
            if (user == null) {
                log.warn("⚠️ User not found for email: {}", email);
            }
            return user;
        } catch (Exception e) {
            log.error("❌ Error getting current user: {}", e.getMessage());
            return null;
        }
    }

    private Long getCurrentUserId() {
        User user = getCurrentUser();
        return user != null ? user.getId() : null;
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
        private String word;
        private DictionaryLookupResult dictionaryResult;
        private List<ImageInfo> imageSuggestions;
    }

    @Data
    public static class FlashcardCreateRequest {
        private String word;
        private String partOfSpeech;
        private String partOfSpeechVi;    // ✅ Field này đã có
        private String phonetic;
        private String meaning;           // Vietnamese
        private String definition;        // English
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