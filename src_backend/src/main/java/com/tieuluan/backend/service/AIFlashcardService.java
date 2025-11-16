package com.tieuluan.backend.service;

import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.Flashcard;
import com.tieuluan.backend.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

/**
 * Service chính để orchestrate toàn bộ luồng tạo flashcard bằng AI
 *
 * ✅ FIXED: Sửa lỗi syntax và category handling
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AIFlashcardService {

    private final GeminiService geminiService;
    private final GoogleCloudStorageService cloudStorageService;
    private final PexelsService pexelsService;
    private final FlashcardService flashcardService;
    private final CategoryRepository categoryRepository; // ✅ THÊM: Cần repository để load Category

    /**
     * DTO cho request tạo flashcard
     */
    public static class CreateFlashcardRequest {
        public String term;
        public Long categoryId;
        public boolean generateImage = true;
        public boolean generateAudio = true;

        public CreateFlashcardRequest() {}

        public CreateFlashcardRequest(String term) {
            this.term = term;
        }
    }

    /**
     * DTO cho response
     */
    public static class CreateFlashcardResponse {
        public boolean success;
        public String message;
        public Flashcard flashcard;
        public StepStatus steps;

        public CreateFlashcardResponse() {
            this.steps = new StepStatus();
        }
    }

    public static class StepStatus {
        public boolean aiContentGenerated = false;
        public boolean audioGenerated = false;
        public boolean imageFound = false;
        public boolean savedToDatabase = false;

        public String aiError;
        public String audioError;
        public String imageError;
        public String databaseError;
    }

    /**
     * Tạo flashcard hoàn chỉnh từ một từ vựng
     */
    public CreateFlashcardResponse generateFlashcard(CreateFlashcardRequest request) {
        CreateFlashcardResponse response = new CreateFlashcardResponse();

        try {
            log.info("🚀 Starting AI flashcard generation for: {}", request.term);

            // Validate input
            if (request.term == null || request.term.trim().isEmpty()) {
                response.success = false;
                response.message = "Term cannot be empty";
                return response;
            }

            String term = request.term.trim();

            // ============ STEP 1: Generate content with Gemini AI ============
            GeminiService.FlashcardContent content;
            try {
                log.info("📝 Step 1/4: Generating content with Gemini AI...");
                content = geminiService.generateFlashcardContent(term);
                response.steps.aiContentGenerated = true;
                log.info("✅ Step 1 completed: AI content generated");

                // ✨ LOG content để debug
                log.info("📦 Content received:");
                log.info("   - term: {}", content.term);
                log.info("   - partOfSpeech: {}", content.partOfSpeech);
                log.info("   - phonetic: {}", content.phonetic);
                log.info("   - translation: {}", content.translation);
                log.info("   - example: {}", content.example);
                log.info("   - exampleTranslation: {}", content.exampleTranslation);

            } catch (Exception e) {
                log.error("❌ Step 1 failed: {}", e.getMessage(), e);
                response.steps.aiError = e.getMessage();
                response.success = false;
                response.message = "Failed to generate AI content: " + e.getMessage();
                return response;
            }

            // ============ STEP 2: Generate and upload audio ============
            String ttsUrl = null;
            if (request.generateAudio) {
                try {
                    log.info("🎵 Step 2/4: Generating audio with Google TTS...");
                    ttsUrl = cloudStorageService.createAndUploadAudio(term, "en-US");
                    response.steps.audioGenerated = (ttsUrl != null);
                    if (ttsUrl != null) {
                        log.info("✅ Step 2 completed: Audio uploaded to {}", ttsUrl);
                    } else {
                        log.warn("⚠️ Step 2 warning: Audio generation returned null, continuing...");
                    }
                } catch (Exception e) {
                    log.error("⚠️ Step 2 error: {}", e.getMessage());
                    response.steps.audioError = e.getMessage();
                    // Continue even if audio generation fails
                }
            } else {
                log.info("⏭️ Step 2 skipped: Audio generation disabled");
            }

            // ============ STEP 3: Find image with Pexels ============
            String imageUrl = null;
            if (request.generateImage) {
                try {
                    log.info("🖼️ Step 3/4: Finding image with Pexels...");

                    // ✨ TRY 1: Tìm bằng example (intelligent)
                    if (content.example != null && !content.example.isEmpty()) {
                        imageUrl = pexelsService.findImageFromExample(term, content.example);
                        log.info("📸 Tried finding image from example: {}", imageUrl != null ? "SUCCESS" : "FAILED");
                    }

                    // ✨ TRY 2: Fallback - tìm bằng term
                    if (imageUrl == null) {
                        log.info("🔄 Fallback: Searching by term only");
                        imageUrl = pexelsService.findImage(term);
                        log.info("📸 Tried finding image by term: {}", imageUrl != null ? "SUCCESS" : "FAILED");
                    }

                    response.steps.imageFound = (imageUrl != null);
                    if (imageUrl != null) {
                        log.info("✅ Step 3 completed: Image found at {}", imageUrl);
                    } else {
                        log.warn("⚠️ Step 3 warning: No suitable image found, continuing without image...");
                    }
                } catch (Exception e) {
                    log.error("⚠️ Step 3 error: {}", e.getMessage());
                    response.steps.imageError = e.getMessage();
                    // Continue even if image search fails
                }
            } else {
                log.info("⏭️ Step 3 skipped: Image search disabled");
            }

            // ============ STEP 4: Create and save flashcard ============
            try {
                log.info("💾 Step 4/4: Saving flashcard to database...");

                Flashcard flashcard = new Flashcard();
                flashcard.setTerm(content.term);
                flashcard.setPartOfSpeech(content.partOfSpeech);
                flashcard.setPhonetic(content.phonetic);

                // ✅ SIMPLIFIED: Chỉ lưu nghĩa tiếng Việt thôi
                String meaning = content.translation != null && !content.translation.isEmpty()
                        ? content.translation
                        : "No translation available";

                flashcard.setMeaning(meaning);
                flashcard.setImageUrl(imageUrl);
                flashcard.setTtsUrl(ttsUrl);

                // ✅ FIXED: Load Category từ DB thay vì new
                if (request.categoryId != null) {
                    Category category = categoryRepository.findById(request.categoryId)
                            .orElseThrow(() -> new RuntimeException("Category not found with ID: " + request.categoryId));
                    flashcard.setCategory(category);
                }

                log.info("📝 Flashcard to save:");
                log.info("   - term: {}", flashcard.getTerm());
                log.info("   - partOfSpeech: {}", flashcard.getPartOfSpeech());
                log.info("   - phonetic: {}", flashcard.getPhonetic());
                log.info("   - meaning: {}", flashcard.getMeaning());
                log.info("   - imageUrl: {}", flashcard.getImageUrl());
                log.info("   - ttsUrl: {}", flashcard.getTtsUrl());
                log.info("   - categoryId: {}", flashcard.getCategory() != null ? flashcard.getCategory().getId() : null);

                Flashcard savedFlashcard = flashcardService.createFlashcard(flashcard);
                response.steps.savedToDatabase = true;

                response.flashcard = savedFlashcard;
                response.success = true;
                response.message = "Flashcard created successfully!";

                log.info("✅ Step 4 completed: Flashcard saved with ID {}", savedFlashcard.getId());
                log.info("🎉 AI flashcard generation completed successfully for: {}", term);

            } catch (Exception e) {
                log.error("❌ Step 4 failed: {}", e.getMessage(), e);
                response.steps.databaseError = e.getMessage();
                response.success = false;
                response.message = "Failed to save flashcard: " + e.getMessage();
                return response;
            }

            return response;

        } catch (Exception e) {
            // ✅ FIXED: Thêm catch block tổng thể
            log.error("❌ Unexpected error in AI flashcard generation: {}", e.getMessage(), e);
            response.success = false;
            response.message = "Unexpected error: " + e.getMessage();
            return response;
        }
    }

    /**
     * Batch generate flashcards từ nhiều từ vựng
     */
    public CreateFlashcardResponse[] batchGenerateFlashcards(String[] terms, Long categoryId) {
        CreateFlashcardResponse[] responses = new CreateFlashcardResponse[terms.length];

        for (int i = 0; i < terms.length; i++) {
            CreateFlashcardRequest request = new CreateFlashcardRequest(terms[i]);
            request.categoryId = categoryId;

            responses[i] = generateFlashcard(request);

            // Delay nhỏ giữa các requests để tránh rate limit
            try {
                Thread.sleep(500);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        return responses;
    }

    /**
     * Kiểm tra xem tất cả services có được cấu hình đúng chưa
     */
    public Map<String, Boolean> checkServicesStatus() {
        Map<String, Boolean> status = new java.util.HashMap<>();

        status.put("gemini", geminiService.isConfigured());
        status.put("googleCloud", cloudStorageService.isConfigured());
        status.put("pexels", pexelsService.isConfigured());

        log.info("🔍 Services status check:");
        log.info("   - Gemini: {}", status.get("gemini"));
        log.info("   - Google Cloud: {}", status.get("googleCloud"));
        log.info("   - Pexels: {}", status.get("pexels"));

        return status;
    }


}