// File: GeminiService.java
package com.tieuluan.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service tích hợp Google Gemini AI để tạo nội dung flashcard
 *
 * ✨ SIMPLIFIED: Chỉ tạo những field cần thiết cho UI
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GeminiService {

    @Value("${gemini.api.key}")
    private String apiKey;

    @Value("${gemini.api.url:https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent}")
    private String apiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * DTO cho kết quả từ Gemini AI
     */
    public static class FlashcardContent {
        public String term;
        public String partOfSpeech;      // English: noun, verb, adjective...
        public String phonetic;          // IPA: /bæŋk/
        public String translation;       // Vietnamese: Ngân hàng
        public String example;           // Example sentence
        public String exampleTranslation; // Vietnamese example translation

        public FlashcardContent() {}
    }

    /**
     * Tạo nội dung flashcard từ một từ vựng bằng Gemini AI
     */
    public FlashcardContent generateFlashcardContent(String term) {
        try {
            log.info("🤖 Generating flashcard content for term: {}", term);

            // Tạo prompt cho Gemini
            String prompt = createPrompt(term);

            // Gọi Gemini API
            String response = callGeminiAPI(prompt);

            // Parse JSON response
            FlashcardContent content = parseGeminiResponse(response);

            log.info("✅ Successfully generated content for: {}", term);
            return content;

        } catch (Exception e) {
            log.error("❌ Error generating flashcard content: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to generate flashcard content: " + e.getMessage(), e);
        }
    }

    /**
     * ✨ ULTRA SIMPLIFIED PROMPT
     * Chỉ tạo những field cần thiết cho màn hình flashcard
     */
    private String createPrompt(String term) {
        return String.format("""
            Create a flashcard for the English word "%s".
            
            Return ONLY a JSON object (no markdown, no code blocks):
            {
                "term": "%s",
                "partOfSpeech": "noun",
                "phonetic": "/IPA/",
                "translation": "Vietnamese translation",
                "example": "Example sentence",
                "exampleTranslation": "Vietnamese example translation"
            }
            
            RULES:
            1. partOfSpeech: English (noun/verb/adjective/adverb/etc)
            2. phonetic: IPA notation with slashes
            3. translation: Clear, concise Vietnamese meaning (1-3 words if possible)
            4. example: Natural sentence, 5-12 words
            5. exampleTranslation: Vietnamese translation of example
            6. Return ONLY valid JSON, nothing else
            7. Do NOT include line breaks inside string values
            
            Example for "bank":
            {
                "term": "bank",
                "partOfSpeech": "noun",
                "phonetic": "/bæŋk/",
                "translation": "Ngân hàng",
                "example": "I went to the bank to deposit money",
                "exampleTranslation": "Tôi đến ngân hàng để gửi tiền"
            }
            """, term, term);
    }

    /**
     * Gọi Gemini API
     */
    private String callGeminiAPI(String prompt) {
        try {
            String url = apiUrl + "?key=" + apiKey;

            // Request body
            Map<String, Object> requestBody = new HashMap<>();
            Map<String, Object> content = new HashMap<>();
            content.put("parts", List.of(Map.of("text", prompt)));
            requestBody.put("contents", List.of(content));

            // Generation config
            Map<String, Object> generationConfig = new HashMap<>();
            generationConfig.put("temperature", 0.3); // ✨ Thấp hơn để consistent
            generationConfig.put("topK", 40);
            generationConfig.put("topP", 0.95);
            generationConfig.put("maxOutputTokens", 1024);
            requestBody.put("generationConfig", generationConfig);

            // Headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

            log.info("📤 Calling Gemini API...");

            // Call API
            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    request,
                    String.class
            );

            if (response.getStatusCode() == HttpStatus.OK) {
                log.info("✅ Gemini API responded successfully");
                return response.getBody();
            } else {
                throw new RuntimeException("Gemini API returned status: " + response.getStatusCode());
            }

        } catch (Exception e) {
            log.error("❌ Error calling Gemini API: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to call Gemini API: " + e.getMessage(), e);
        }
    }

    /**
     * ✨ IMPROVED: Parse response với better error handling
     */
    private FlashcardContent parseGeminiResponse(String response) {
        try {
            log.info("📥 Parsing Gemini response...");

            JsonNode root = objectMapper.readTree(response);

            // Lấy text từ response
            JsonNode candidates = root.path("candidates");
            if (candidates.isEmpty()) {
                throw new RuntimeException("No candidates in Gemini response");
            }

            String text = candidates.get(0)
                    .path("content")
                    .path("parts")
                    .get(0)
                    .path("text")
                    .asText();

            if (text == null || text.isEmpty()) {
                throw new RuntimeException("Empty text in Gemini response");
            }

            log.info("📄 Raw response text length: {}", text.length());

            // ✨ Clean JSON text
            text = cleanJsonText(text);

            log.info("🧹 Cleaned text (first 200 chars): {}",
                    text.substring(0, Math.min(200, text.length())));

            // ✨ Parse JSON
            FlashcardContent content;
            try {
                content = objectMapper.readValue(text, FlashcardContent.class);
            } catch (Exception parseEx) {
                log.error("❌ JSON Parse Error. Text was: {}", text);
                throw new RuntimeException("Failed to parse JSON: " + parseEx.getMessage());
            }

            // ✨ VALIDATE required fields
            if (content.term == null || content.term.isEmpty()) {
                throw new RuntimeException("Missing 'term' field in response");
            }
            if (content.translation == null || content.translation.isEmpty()) {
                throw new RuntimeException("Missing 'translation' field in response");
            }

            log.info("✅ Successfully parsed flashcard content:");
            log.info("   - Term: {}", content.term);
            log.info("   - Part of Speech: {}", content.partOfSpeech);
            log.info("   - Phonetic: {}", content.phonetic);
            log.info("   - Translation: {}", content.translation);
            log.info("   - Example: {}", content.example);
            log.info("   - Example Translation: {}", content.exampleTranslation);

            return content;

        } catch (Exception e) {
            log.error("❌ Error parsing Gemini response: {}", e.getMessage(), e);
            log.error("📄 Full response was: {}", response);
            throw new RuntimeException("Failed to parse Gemini response: " + e.getMessage(), e);
        }
    }

    /**
     * ✨ HELPER: Clean JSON text từ response
     */
    private String cleanJsonText(String text) {
        // Remove leading/trailing whitespace
        text = text.trim();

        // Remove markdown code blocks
        if (text.startsWith("```json")) {
            text = text.substring(7);
        } else if (text.startsWith("```")) {
            text = text.substring(3);
        }

        if (text.endsWith("```")) {
            text = text.substring(0, text.length() - 3);
        }

        // Remove any leading/trailing whitespace again
        text = text.trim();

        // ✨ Remove any text before first {
        int firstBrace = text.indexOf('{');
        if (firstBrace > 0) {
            log.warn("⚠️ Removing text before first brace: {}",
                    text.substring(0, firstBrace));
            text = text.substring(firstBrace);
        }

        // ✨ Remove any text after last }
        int lastBrace = text.lastIndexOf('}');
        if (lastBrace > 0 && lastBrace < text.length() - 1) {
            log.warn("⚠️ Removing text after last brace: {}",
                    text.substring(lastBrace + 1));
            text = text.substring(0, lastBrace + 1);
        }

        return text;
    }

    /**
     * Kiểm tra xem API key có được cấu hình chưa
     */
    public boolean isConfigured() {
        return apiKey != null && !apiKey.isEmpty() && !apiKey.equals("AIzaSyCCUvSw2KAaJq-Ohgho1eRqfTRD0bMfQCA");
    }
}