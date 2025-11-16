package com.tieuluan.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/**
 * Service tích hợp Pexels API để tìm ảnh minh họa cho flashcard
 * ✅ DEBUG VERSION - Chi tiết logging
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PexelsService {

    @Value("${pexels.api.key}")
    private String apiKey;

    @Value("${pexels.api.url:https://api.pexels.com/v1/search}")
    private String apiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * ✅ MAIN METHOD: Tìm ảnh phù hợp cho flashcard
     */
    public String findImage(String searchQuery) {
        log.info("🔍 ===== PEXELS IMAGE SEARCH START =====");
        log.info("📝 Search query: '{}'", searchQuery);

        try {
            // ✅ Check API key first
            if (!isConfigured()) {
                log.error("❌ Pexels API key not configured!");
                log.error("📍 Current API key value: '{}'", apiKey != null ? apiKey.substring(0, Math.min(20, apiKey.length())) + "..." : "NULL");
                log.error("📍 Please set pexels.api.key in application.properties");
                log.info("🔍 ===== PEXELS IMAGE SEARCH FAILED (NO API KEY) =====");
                return null;
            }

            log.info("✅ Pexels API key is configured");
            log.info("🔑 API Key prefix: {}...", apiKey.substring(0, Math.min(10, apiKey.length())));

            // ✅ Try 1: Original query
            String imageUrl = searchPexels(searchQuery);

            if (imageUrl != null) {
                log.info("✅ Found image on first try: {}", imageUrl);
                log.info("🔍 ===== PEXELS IMAGE SEARCH SUCCESS =====");
                return imageUrl;
            }

            // ✅ Try 2: Simple fallback
            if (searchQuery.contains(" ")) {
                String simpleQuery = searchQuery.split(" ")[0];
                log.info("🔄 First attempt failed. Trying simpler query: '{}'", simpleQuery);
                imageUrl = searchPexels(simpleQuery);

                if (imageUrl != null) {
                    log.info("✅ Found image on second try: {}", imageUrl);
                    log.info("🔍 ===== PEXELS IMAGE SEARCH SUCCESS =====");
                    return imageUrl;
                }
            }

            // ✅ Try 3: Generic fallback
            log.info("🔄 Both attempts failed. Trying generic 'education' as fallback");
            imageUrl = searchPexels("education");

            if (imageUrl != null) {
                log.info("✅ Found image on generic fallback: {}", imageUrl);
                log.info("🔍 ===== PEXELS IMAGE SEARCH SUCCESS =====");
                return imageUrl;
            }

            log.warn("⚠️ No image found for: '{}' even with all fallbacks", searchQuery);
            log.info("🔍 ===== PEXELS IMAGE SEARCH FAILED (NO RESULTS) =====");
            return null;

        } catch (Exception e) {
            log.error("❌ Error finding image: {}", e.getMessage(), e);
            log.info("🔍 ===== PEXELS IMAGE SEARCH ERROR =====");
            return null;
        }
    }

    /**
     * ✅ IMPROVED: Tìm ảnh dựa trên example sentence
     */
    public String findImageFromExample(String term, String example) {
        log.info("🔍 ===== PEXELS IMAGE FROM EXAMPLE START =====");
        log.info("📝 Term: '{}'", term);
        log.info("📝 Example: '{}'", example);

        try {
            if (!isConfigured()) {
                log.error("❌ Pexels API key not configured!");
                log.info("🔍 ===== PEXELS IMAGE FROM EXAMPLE FAILED =====");
                return null;
            }

            // Extract key phrase from example
            String searchQuery = extractKeyPhrase(term, example);
            log.info("🔑 Extracted search query: '{}'", searchQuery);

            String imageUrl = searchPexels(searchQuery);

            // Fallback to term only
            if (imageUrl == null) {
                log.info("🔄 Example-based search failed, trying term only: '{}'", term);
                imageUrl = searchPexels(term);
            }

            // Fallback to generic
            if (imageUrl == null) {
                log.info("🔄 Term search failed, trying 'education'");
                imageUrl = searchPexels("education");
            }

            if (imageUrl != null) {
                log.info("✅ Found image from example: {}", imageUrl);
            } else {
                log.warn("⚠️ No image found from example");
            }

            log.info("🔍 ===== PEXELS IMAGE FROM EXAMPLE END =====");
            return imageUrl;

        } catch (Exception e) {
            log.error("❌ Error finding image from example: {}", e.getMessage(), e);
            log.info("🔍 ===== PEXELS IMAGE FROM EXAMPLE ERROR =====");
            return null;
        }
    }

    /**
     * Extract key phrase từ example sentence
     */
    private String extractKeyPhrase(String term, String example) {
        if (example == null || example.isEmpty()) {
            return term;
        }

        String lowerExample = example.toLowerCase();
        String lowerTerm = term.toLowerCase();
        int termIndex = lowerExample.indexOf(lowerTerm);

        if (termIndex != -1) {
            String[] words = example.split("\\s+");
            StringBuilder query = new StringBuilder(term);
            int maxWords = 5;
            int count = 0;

            for (String word : words) {
                if (count >= maxWords) break;
                String cleanWord = word.toLowerCase().replaceAll("[^a-z]", "");
                if (!cleanWord.isEmpty() && !cleanWord.equals(lowerTerm)
                        && !isStopWord(cleanWord) && cleanWord.length() > 5) {
                    query.append(" ").append(cleanWord);
                    count++;
                }
            }
            return query.toString().trim();
        }
        return term;
    }

    /**
     * Kiểm tra stop word
     */
    private boolean isStopWord(String word) {
        String[] stopWords = {"the", "a", "an", "and", "or", "but", "in", "on", "at",
                "to", "for", "of", "with", "by", "from", "is", "was", "are", "were"};
        for (String stop : stopWords) {
            if (word.equals(stop)) return true;
        }
        return false;
    }

    /**
     * ✅ CORE: Gọi Pexels API
     */
    private String searchPexels(String query) {
        log.info("📡 ===== CALLING PEXELS API =====");
        log.info("🔎 Query: '{}'", query);

        try {
            String encodedQuery = URLEncoder.encode(query, StandardCharsets.UTF_8);
            String url = apiUrl + "?query=" + encodedQuery + "&per_page=5&orientation=landscape";

            log.info("🌐 URL: {}", url);
            log.info("🔑 API Key: {}...", apiKey.substring(0, Math.min(15, apiKey.length())));

            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", apiKey);
            headers.set("User-Agent", "FlashcardApp/1.0");

            HttpEntity<String> request = new HttpEntity<>(headers);

            log.info("📤 Sending request...");
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, request, String.class);

            log.info("📥 Response status: {}", response.getStatusCode());
            log.info("📥 Response body length: {} chars", response.getBody() != null ? response.getBody().length() : 0);

            if (response.getStatusCode() == HttpStatus.OK) {
                String body = response.getBody();
                if (body == null || body.isEmpty()) {
                    log.warn("⚠️ Empty response body");
                    return null;
                }

                String imageUrl = parseImageUrl(body);

                if (imageUrl != null) {
                    log.info("✅ Image URL extracted: {}", imageUrl);
                } else {
                    log.warn("⚠️ No photos found in response");
                }

                log.info("📡 ===== PEXELS API CALL END =====");
                return imageUrl;
            } else {
                log.warn("⚠️ Non-OK status: {}", response.getStatusCode());
                log.info("📡 ===== PEXELS API CALL FAILED =====");
                return null;
            }

        } catch (org.springframework.web.client.HttpClientErrorException e) {
            log.error("❌ HTTP Error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());

            if (e.getStatusCode() == HttpStatus.FORBIDDEN) {
                log.error("🚫 403 FORBIDDEN: API key may be invalid!");
            } else if (e.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                log.error("🔐 401 UNAUTHORIZED: Check API key format!");
            } else if (e.getStatusCode() == HttpStatus.TOO_MANY_REQUESTS) {
                log.error("⏰ 429 RATE LIMIT: Too many requests!");
            }

            log.info("📡 ===== PEXELS API CALL ERROR =====");
            return null;
        } catch (Exception e) {
            log.error("❌ Unexpected error: {}", e.getMessage());
            e.printStackTrace();
            log.info("📡 ===== PEXELS API CALL ERROR =====");
            return null;
        }
    }

    /**
     * Parse image URL từ Pexels response
     */
    private String parseImageUrl(String response) {
        try {
            JsonNode root = objectMapper.readTree(response);
            JsonNode photos = root.path("photos");

            log.info("📸 Photos found in response: {}", photos.size());

            if (photos.isArray() && photos.size() > 0) {
                JsonNode firstPhoto = photos.get(0);

                String largeUrl = firstPhoto.path("src").path("large").asText();
                String mediumUrl = firstPhoto.path("src").path("medium").asText();
                String originalUrl = firstPhoto.path("src").path("original").asText();

                log.info("📊 Available image sizes:");
                log.info("   - Large: {}", largeUrl);
                log.info("   - Medium: {}", mediumUrl);
                log.info("   - Original: {}", originalUrl);

                if (largeUrl != null && !largeUrl.isEmpty() && !largeUrl.equals("null")) {
                    log.info("✅ Using large image");
                    return largeUrl;
                } else if (mediumUrl != null && !mediumUrl.isEmpty() && !mediumUrl.equals("null")) {
                    log.info("✅ Using medium image");
                    return mediumUrl;
                } else if (originalUrl != null && !originalUrl.isEmpty() && !originalUrl.equals("null")) {
                    log.info("✅ Using original image");
                    return originalUrl;
                }
            }

            log.warn("⚠️ No valid photos in response");
            return null;

        } catch (Exception e) {
            log.error("❌ Error parsing response: {}", e.getMessage());
            return null;
        }
    }

    /**
     * ✅ Check if API key is configured
     */
    public boolean isConfigured() {
        boolean hasKey = apiKey != null && !apiKey.isEmpty();
        boolean isNotPlaceholder = apiKey.equals("LD3xh4nDMPUMdi1kZVyC5Y1yXdQSkgIGliYek50R1G1HhD8hTKMs2Hg0");
        boolean configured = hasKey && isNotPlaceholder;

        if (!configured) {
            log.debug("⚠️ Pexels not configured. Has key: {}, Is placeholder: {}", hasKey, !isNotPlaceholder);
        }

        return configured;
    }

    /**
     * ✅ TEST METHOD
     */
    public boolean testConnection() {
        try {
            log.info("🧪 Testing Pexels connection...");
            String result = searchPexels("test");

            if (result != null) {
                log.info("✅ Pexels connection OK");
                return true;
            } else {
                log.warn("⚠️ Pexels connection test - no results");
                return false;
            }
        } catch (Exception e) {
            log.error("❌ Pexels connection test failed: {}", e.getMessage());
            return false;
        }
    }
}