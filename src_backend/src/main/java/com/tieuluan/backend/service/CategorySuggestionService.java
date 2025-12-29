package com.tieuluan.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tieuluan.backend.model.Category;
import com.tieuluan.backend.model.User;
import com.tieuluan.backend.repository.CategoryRepository;
import com.tieuluan.backend.repository.UserRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Service gợi ý Category phù hợp cho từ vựng
 * Sử dụng Gemini AI để phân loại
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CategorySuggestionService {

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    @Value("${gemini.api.key}")
    private String geminiApiKey;

    @Value("${gemini.api.url:https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent}")
    private String geminiApiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Gợi ý categories phù hợp cho từ vựng
     * @param word Từ vựng
     * @param meaning Nghĩa tiếng Việt (optional)
     * @param partOfSpeech Loại từ (optional)
     * @return Danh sách categories được gợi ý
     */
    public CategorySuggestionResult suggestCategories(String word, String meaning, String partOfSpeech) {
        log.info("🏷️ Suggesting categories for word: '{}'", word);

        CategorySuggestionResult result = new CategorySuggestionResult();
        result.setWord(word);

        try {
            // 1. Lấy danh sách categories của user
            Long userId = getCurrentUserId();
            List<Category> userCategories = getUserAccessibleCategories(userId);

            if (userCategories.isEmpty()) {
                result.setSuccess(false);
                result.setMessage("Bạn chưa có category nào. Hãy tạo category trước.");
                result.setSuggestions(List.of());
                return result;
            }

            log.info("📋 Found {} accessible categories for user", userCategories.size());

            // 2. Gọi Gemini AI để phân loại
            List<CategorySuggestion> suggestions = classifyWithAI(word, meaning, partOfSpeech, userCategories);

            result.setSuccess(true);
            result.setMessage("Đã phân tích và gợi ý " + suggestions.size() + " categories");
            result.setSuggestions(suggestions);
            result.setTotalCategories(userCategories.size());

            return result;

        } catch (Exception e) {
            log.error("❌ Error suggesting categories: {}", e.getMessage(), e);
            result.setSuccess(false);
            result.setMessage("Lỗi khi phân loại: " + e.getMessage());
            result.setSuggestions(List.of());
            return result;
        }
    }

    /**
     * Gọi Gemini AI để phân loại từ vựng
     */
    private List<CategorySuggestion> classifyWithAI(String word, String meaning, String partOfSpeech,
                                                    List<Category> categories) {
        try {
            // Build danh sách categories cho prompt
            String categoryList = categories.stream()
                    .map(c -> String.format("- ID %d: \"%s\" (%s)",
                            c.getId(),
                            c.getName(),
                            c.getDescription() != null ? c.getDescription() : "Không có mô tả"))
                    .collect(Collectors.joining("\n"));

            // Build prompt
            String prompt = buildClassificationPrompt(word, meaning, partOfSpeech, categoryList);

            // Gọi Gemini API
            String response = callGeminiAPI(prompt);

            // Parse response
            return parseAIResponse(response, categories);

        } catch (Exception e) {
            log.error("❌ Error calling AI: {}", e.getMessage());

            // Fallback: trả về tất cả categories với score mặc định
            return categories.stream()
                    .limit(5)
                    .map(c -> {
                        CategorySuggestion s = new CategorySuggestion();
                        s.setCategoryId(c.getId());
                        s.setCategoryName(c.getName());
                        s.setDescription(c.getDescription());
                        s.setConfidenceScore(0.5);
                        s.setReason("Gợi ý mặc định (AI không khả dụng)");
                        return s;
                    })
                    .collect(Collectors.toList());
        }
    }

    /**
     * Build prompt cho Gemini
     */
    private String buildClassificationPrompt(String word, String meaning, String partOfSpeech,
                                             String categoryList) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("Phân loại từ vựng vào các category phù hợp nhất.\n\n");
        prompt.append("TỪ VỰNG:\n");
        prompt.append("- Từ: ").append(word).append("\n");

        if (meaning != null && !meaning.isEmpty()) {
            prompt.append("- Nghĩa: ").append(meaning).append("\n");
        }
        if (partOfSpeech != null && !partOfSpeech.isEmpty()) {
            prompt.append("- Loại từ: ").append(partOfSpeech).append("\n");
        }

        prompt.append("\nDANH SÁCH CATEGORIES:\n");
        prompt.append(categoryList);

        prompt.append("\n\nTRẢ VỀ JSON (không markdown):\n");
        prompt.append("{\n");
        prompt.append("  \"suggestions\": [\n");
        prompt.append("    {\n");
        prompt.append("      \"categoryId\": <số ID>,\n");
        prompt.append("      \"confidenceScore\": <0.0-1.0>,\n");
        prompt.append("      \"reason\": \"Lý do ngắn gọn\"\n");
        prompt.append("    }\n");
        prompt.append("  ]\n");
        prompt.append("}\n\n");
        prompt.append("QUY TẮC:\n");
        prompt.append("1. Chỉ gợi ý tối đa 3 categories phù hợp nhất\n");
        prompt.append("2. confidenceScore từ 0.0 (không phù hợp) đến 1.0 (rất phù hợp)\n");
        prompt.append("3. Sắp xếp theo confidenceScore giảm dần\n");
        prompt.append("4. Chỉ trả về JSON, không giải thích thêm\n");

        return prompt.toString();
    }

    /**
     * Gọi Gemini API
     */
    private String callGeminiAPI(String prompt) throws Exception {
        String url = geminiApiUrl + "?key=" + geminiApiKey;

        Map<String, Object> requestBody = new HashMap<>();
        Map<String, Object> content = new HashMap<>();
        content.put("parts", List.of(Map.of("text", prompt)));
        requestBody.put("contents", List.of(content));

        Map<String, Object> generationConfig = new HashMap<>();
        generationConfig.put("temperature", 0.3);
        generationConfig.put("maxOutputTokens", 512);
        requestBody.put("generationConfig", generationConfig);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

        ResponseEntity<String> response = restTemplate.exchange(
                url, HttpMethod.POST, request, String.class);

        if (response.getStatusCode() == HttpStatus.OK) {
            return response.getBody();
        } else {
            throw new RuntimeException("Gemini API error: " + response.getStatusCode());
        }
    }

    /**
     * Parse response từ Gemini
     */
    private List<CategorySuggestion> parseAIResponse(String response, List<Category> categories) {
        List<CategorySuggestion> suggestions = new ArrayList<>();

        try {
            JsonNode root = objectMapper.readTree(response);
            String text = root.path("candidates").get(0)
                    .path("content").path("parts").get(0)
                    .path("text").asText();

            // Clean JSON
            text = cleanJsonText(text);

            JsonNode jsonResponse = objectMapper.readTree(text);
            JsonNode suggestionsArray = jsonResponse.path("suggestions");

            if (suggestionsArray.isArray()) {
                // Map categories by ID for quick lookup
                Map<Long, Category> categoryMap = categories.stream()
                        .collect(Collectors.toMap(Category::getId, c -> c));

                for (JsonNode node : suggestionsArray) {
                    long categoryId = node.path("categoryId").asLong();
                    Category category = categoryMap.get(categoryId);

                    if (category != null) {
                        CategorySuggestion suggestion = new CategorySuggestion();
                        suggestion.setCategoryId(categoryId);
                        suggestion.setCategoryName(category.getName());
                        suggestion.setDescription(category.getDescription());
                        suggestion.setConfidenceScore(node.path("confidenceScore").asDouble());
                        suggestion.setReason(node.path("reason").asText());
                        suggestions.add(suggestion);
                    }
                }
            }

        } catch (Exception e) {
            log.error("Error parsing AI response: {}", e.getMessage());
        }

        // Sort by confidence score descending
        suggestions.sort((a, b) -> Double.compare(b.getConfidenceScore(), a.getConfidenceScore()));

        return suggestions;
    }

    /**
     * Clean JSON text từ response
     */
    private String cleanJsonText(String text) {
        text = text.trim();

        if (text.startsWith("```json")) {
            text = text.substring(7);
        } else if (text.startsWith("```")) {
            text = text.substring(3);
        }

        if (text.endsWith("```")) {
            text = text.substring(0, text.length() - 3);
        }

        int firstBrace = text.indexOf('{');
        int lastBrace = text.lastIndexOf('}');

        if (firstBrace >= 0 && lastBrace > firstBrace) {
            text = text.substring(firstBrace, lastBrace + 1);
        }

        return text.trim();
    }

    /**
     * Lấy danh sách categories mà user có thể truy cập
     */
    private List<Category> getUserAccessibleCategories(Long userId) {
        if (userId == null) {
            // Chỉ trả về system categories
            return categoryRepository.findByIsSystemTrue();
        }

        List<Category> categories = new ArrayList<>();

        // 1. System categories
        categories.addAll(categoryRepository.findByIsSystemTrue());

        // 2. User's own categories
        categories.addAll(categoryRepository.findByOwnerUserId(userId));

        // 3. Categories từ classes mà user tham gia
        categories.addAll(categoryRepository.findAccessibleByUserId(userId));

        // Remove duplicates
        return categories.stream()
                .distinct()
                .collect(Collectors.toList());
    }

    /**
     * Lấy userId từ Security Context
     */
    private Long getCurrentUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated()) {
                return null;
            }

            String email = auth.getName();
            User user = userRepository.findByEmail(email).orElse(null);
            return user != null ? user.getId() : null;

        } catch (Exception e) {
            log.error("Error getting current user ID", e);
            return null;
        }
    }

    // ================== DTOs ==================

    @Data
    public static class CategorySuggestionResult {
        private boolean success;
        private String message;
        private String word;
        private int totalCategories;
        private List<CategorySuggestion> suggestions;
    }

    @Data
    public static class CategorySuggestion {
        private Long categoryId;
        private String categoryName;
        private String description;
        private double confidenceScore;  // 0.0 - 1.0
        private String reason;           // Lý do AI gợi ý
    }
}