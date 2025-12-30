package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.FlashcardRepository;
import com.tieuluan.backend.repository.UserRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AIFlashcardService {

    private final FlashcardRepository flashcardRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService;
    private final PexelsService pexelsService;
    private final GoogleCloudStorageService gcsService;

    /**
     * ✅ Tạo flashcard với AI - có check category ownership
     */
    @Transactional
    public CreateFlashcardResponse generateFlashcard(CreateFlashcardRequest request) {
        CreateFlashcardResponse response = new CreateFlashcardResponse();

        try {
            log.info("🔨 Starting AI flashcard generation for term: {}", request.term);

            // ✅ Check category ownership nếu có categoryId
            if (request.categoryId != null) {
                Long userId = getCurrentUserId();
                if (!canUserAccessCategory(request.categoryId, userId)) {
                    response.success = false;
                    response.message = "Bạn không có quyền sử dụng category này";
                    return response;
                }
            }

            // 1. ✅ Generate content using Gemini AI
            response.definitionStatus = "processing";
            GeminiService.FlashcardContent content = geminiService.generateFlashcardContent(request.term);

            if (content == null || content.translation == null || content.translation.isEmpty()) {
                response.success = false;
                response.message = "Failed to generate flashcard content";
                response.definitionStatus = "failed";
                return response;
            }

            // Build meaning từ content
            String meaning = buildMeaningText(content);
            response.definitions = meaning;
            response.definitionStatus = "success";
            log.info("✅ Content generated");

            // 2. ✅ Generate image using Pexels
            String imageUrl = null;
            if (request.generateImage) {
                response.imageStatus = "processing";

                // Thử tìm ảnh từ example trước
                if (content.example != null && !content.example.isEmpty()) {
                    imageUrl = pexelsService.findImageFromExample(request.term, content.example);
                }

                // Fallback: tìm theo term
                if (imageUrl == null) {
                    imageUrl = pexelsService.findImage(request.term);
                }

                if (imageUrl != null) {
                    response.imageUrl = imageUrl;
                    response.imageStatus = "success";
                    log.info("✅ Image generated: {}", imageUrl);
                } else {
                    response.imageStatus = "skipped";
                    log.warn("⚠️ Image generation skipped");
                }
            } else {
                response.imageStatus = "skipped";
            }

            // 3. ✅ Generate audio using Google TTS
            String audioUrl = null;
            if (request.generateAudio) {
                response.audioStatus = "processing";
                audioUrl = gcsService.createAndUploadAudio(request.term, "en-US");

                if (audioUrl != null) {
                    response.audioUrl = audioUrl;
                    response.audioStatus = "success";
                    log.info("✅ Audio generated: {}", audioUrl);
                } else {
                    response.audioStatus = "failed";
                    log.warn("⚠️ Audio generation failed");
                }
            } else {
                response.audioStatus = "skipped";
            }

            // 4. ✅ FIXED: Tạo Flashcard entity và lưu vào DB - dùng setWord() thay vì setTerm()
            Flashcard flashcard = new Flashcard();
            flashcard.setWord(request.term);  // ✅ FIXED: setWord() thay vì setTerm()
            flashcard.setPartOfSpeech(content.partOfSpeech);
            flashcard.setPhonetic(content.phonetic);
            flashcard.setMeaning(meaning);
            flashcard.setImageUrl(imageUrl);
            flashcard.setTtsUrl(audioUrl);

            // Set user nếu có
            Long userId = getCurrentUserId();
            if (userId != null) {
                User user = userRepository.findById(userId).orElse(null);
                flashcard.setUser(user);
            }

            // Gán category nếu có
            if (request.categoryId != null) {
                Category category = categoryRepository.findById(request.categoryId)
                        .orElseThrow(() -> new RuntimeException("Category not found"));
                flashcard.setCategory(category);
            }

            // Lưu flashcard
            Flashcard saved = flashcardRepository.save(flashcard);

            response.flashcardId = saved.getId();
            response.success = true;
            response.message = "Flashcard generated successfully";

            log.info("✅ Flashcard saved with ID: {}", saved.getId());
            return response;

        } catch (Exception e) {
            log.error("❌ Error generating flashcard: {}", e.getMessage(), e);
            response.success = false;
            response.message = "Error: " + e.getMessage();
            return response;
        }
    }

    /**
     * ✅ Helper: Build meaning text từ GeminiContent
     */
    private String buildMeaningText(GeminiService.FlashcardContent content) {
        StringBuilder meaning = new StringBuilder();

        // Translation
        if (content.translation != null && !content.translation.isEmpty()) {
            meaning.append(content.translation);
        }

        // Example + translation
        if (content.example != null && !content.example.isEmpty()) {
            meaning.append("\n\nExample: ").append(content.example);

            if (content.exampleTranslation != null && !content.exampleTranslation.isEmpty()) {
                meaning.append("\n(").append(content.exampleTranslation).append(")");
            }
        }

        return meaning.toString();
    }

    /**
     * ✅ Batch generate với category ownership check
     */
    @Transactional
    public CreateFlashcardResponse[] batchGenerateFlashcards(String[] terms, Long categoryId) {
        CreateFlashcardResponse[] responses = new CreateFlashcardResponse[terms.length];

        // ✅ Check category ownership trước khi batch
        if (categoryId != null) {
            Long userId = getCurrentUserId();
            if (!canUserAccessCategory(categoryId, userId)) {
                for (int i = 0; i < terms.length; i++) {
                    CreateFlashcardResponse errorResponse = new CreateFlashcardResponse();
                    errorResponse.success = false;
                    errorResponse.message = "Bạn không có quyền sử dụng category này";
                    responses[i] = errorResponse;
                }
                return responses;
            }
        }

        for (int i = 0; i < terms.length; i++) {
            CreateFlashcardRequest request = new CreateFlashcardRequest();
            request.term = terms[i];
            request.categoryId = categoryId;
            request.generateImage = true;
            request.generateAudio = true;

            responses[i] = generateFlashcard(request);

            // Delay để tránh rate limit
            try {
                Thread.sleep(500);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        return responses;
    }

    /**
     * Check services status
     */
    public Map<String, Boolean> checkServicesStatus() {
        Map<String, Boolean> status = new HashMap<>();
        status.put("gemini", geminiService.isConfigured());
        status.put("pexels", pexelsService.isConfigured());
        status.put("googleTTS", gcsService.isConfigured());
        return status;
    }

    // ✅ Helper methods để check ownership

    /**
     * Lấy userId từ authentication context
     */
    private Long getCurrentUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
                return null;
            }
            String email = auth.getName();

            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("User không tồn tại"));

            return user.getId();
        } catch (Exception e) {
            log.error("Error getting current user ID", e);
            return null;
        }
    }

    /**
     * Kiểm tra user có quyền access category không
     */
    private boolean canUserAccessCategory(Long categoryId, Long userId) {
        try {
            Category category = categoryRepository.findById(categoryId)
                    .orElse(null);

            if (category == null) {
                return false;
            }

            // System category: anyone can use
            if (category.isSystemCategory()) {
                return true;
            }

            // PUBLIC category: anyone can use
            if (category.isPublic()) {
                return true;
            }

            // PRIVATE category: only owner can use
            if (category.getOwnerUserId() != null && category.getOwnerUserId().equals(userId)) {
                return true;
            }

            return false;
        } catch (Exception e) {
            log.error("Error checking category access", e);
            return false;
        }
    }

    // ================== DTOs ==================

    @Data
    public static class CreateFlashcardRequest {
        public String term;
        public Long categoryId;
        public Boolean generateImage = true;
        public Boolean generateAudio = true;
    }

    @Data
    public static class CreateFlashcardResponse {
        public boolean success;
        public String message;
        public Long flashcardId;

        // Definitions
        public String definitions;
        public String definitionStatus; // "processing", "success", "failed"

        // Image
        public String imageUrl;
        public String imageStatus; // "processing", "success", "failed", "skipped"

        // Audio
        public String audioUrl;
        public String audioStatus; // "processing", "success", "failed", "skipped"
    }
}