package com.tieuluan.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Service gợi ý hình ảnh từ Pexels
 * Trả về 5 ảnh để người dùng chọn
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImageSuggestionService {

    @Value("${pexels.api.key}")
    private String apiKey;

    @Value("${pexels.api.url:https://api.pexels.com/v1/search}")
    private String apiUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final int DEFAULT_IMAGE_COUNT = 5;

    /**
     * Lấy danh sách ảnh gợi ý cho từ vựng
     * @param word Từ vựng cần tìm ảnh
     * @return Danh sách 5 ảnh gợi ý
     */
    public ImageSuggestionResult suggestImages(String word) {
        return suggestImages(word, DEFAULT_IMAGE_COUNT);
    }

    /**
     * Lấy danh sách ảnh gợi ý với số lượng tùy chỉnh
     */
    public ImageSuggestionResult suggestImages(String word, int count) {
        log.info("🖼️ Getting {} image suggestions for: '{}'", count, word);

        ImageSuggestionResult result = new ImageSuggestionResult();
        result.setWord(word);
        result.setImages(new ArrayList<>());

        try {
            if (!isConfigured()) {
                log.error("❌ Pexels API key not configured!");
                result.setSuccess(false);
                result.setMessage("Pexels API chưa được cấu hình");
                return result;
            }

            // Tìm ảnh với từ gốc
            List<ImageInfo> images = searchPexelsImages(word, count);

            // Nếu không đủ ảnh, thử tìm thêm với từ đơn giản hơn
            if (images.size() < count && word.contains(" ")) {
                String simpleWord = word.split(" ")[0];
                log.info("🔄 Not enough images, trying simpler query: '{}'", simpleWord);

                List<ImageInfo> moreImages = searchPexelsImages(simpleWord, count - images.size());
                images.addAll(moreImages);
            }

            // Nếu vẫn không có ảnh, thử với "education" fallback
            if (images.isEmpty()) {
                log.info("🔄 No images found, using generic fallback");
                images = searchPexelsImages("education learning", count);
            }

            result.setImages(images);
            result.setSuccess(!images.isEmpty());
            result.setMessage(images.isEmpty() ? "Không tìm thấy ảnh phù hợp" : "Tìm thấy " + images.size() + " ảnh");
            result.setTotalFound(images.size());

            log.info("✅ Found {} images for '{}'", images.size(), word);
            return result;

        } catch (Exception e) {
            log.error("❌ Error getting image suggestions: {}", e.getMessage(), e);
            result.setSuccess(false);
            result.setMessage("Lỗi khi tìm ảnh: " + e.getMessage());
            return result;
        }
    }

    /**
     * Gọi Pexels API và parse kết quả
     */
    private List<ImageInfo> searchPexelsImages(String query, int count) {
        List<ImageInfo> images = new ArrayList<>();

        try {
            String encodedQuery = URLEncoder.encode(query, StandardCharsets.UTF_8);
            String url = apiUrl + "?query=" + encodedQuery + "&per_page=" + Math.max(count, 5) + "&orientation=landscape";

            log.info("🌐 Calling Pexels: {}", url);

            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", apiKey);
            headers.set("User-Agent", "FlashcardApp/1.0");

            HttpEntity<String> request = new HttpEntity<>(headers);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, request, String.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode photos = root.path("photos");

                if (photos.isArray()) {
                    for (int i = 0; i < Math.min(photos.size(), count); i++) {
                        JsonNode photo = photos.get(i);
                        ImageInfo imageInfo = parsePhotoNode(photo);
                        if (imageInfo != null) {
                            images.add(imageInfo);
                        }
                    }
                }
            }

        } catch (Exception e) {
            log.error("❌ Error searching Pexels: {}", e.getMessage());
        }

        return images;
    }

    /**
     * Parse JSON node thành ImageInfo
     */
    private ImageInfo parsePhotoNode(JsonNode photo) {
        try {
            ImageInfo info = new ImageInfo();

            info.setId(photo.path("id").asLong());
            info.setPhotographer(photo.path("photographer").asText());
            info.setPhotographerUrl(photo.path("photographer_url").asText());
            info.setAlt(photo.path("alt").asText());

            JsonNode src = photo.path("src");
            info.setOriginal(src.path("original").asText());
            info.setLarge(src.path("large").asText());
            info.setMedium(src.path("medium").asText());
            info.setSmall(src.path("small").asText());
            info.setTiny(src.path("tiny").asText());

            // Sử dụng medium làm URL mặc định
            info.setUrl(info.getMedium());

            return info;
        } catch (Exception e) {
            log.error("Error parsing photo: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Kiểm tra API key đã được cấu hình chưa
     */
    public boolean isConfigured() {
        return apiKey != null && !apiKey.isEmpty() && !apiKey.equals("YOUR_API_KEY_HERE");
    }

    // ================== DTOs ==================

    @Data
    public static class ImageSuggestionResult {
        private boolean success;
        private String message;
        private String word;
        private int totalFound;
        private List<ImageInfo> images;
    }

    @Data
    public static class ImageInfo {
        private Long id;
        private String url;           // URL mặc định (medium)
        private String original;      // Full resolution
        private String large;         // 940px wide
        private String medium;        // 350px wide
        private String small;         // 130px wide
        private String tiny;          // 100x100
        private String photographer;
        private String photographerUrl;
        private String alt;           // Mô tả ảnh
    }
}