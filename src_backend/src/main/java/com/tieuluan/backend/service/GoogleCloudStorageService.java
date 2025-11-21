package com.tieuluan.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Service tích hợp Google Cloud Text-to-Speech và Cloud Storage
 * để tạo và lưu trữ file audio cho flashcard
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GoogleCloudStorageService {

    @Value("${google.cloud.api.key}")
    private String apiKey;

    @Value("${google.cloud.storage.bucket}")
    private String bucketName;

    @Value("${google.cloud.tts.url:https://texttospeech.googleapis.com/v1/text:synthesize}")
    private String ttsUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Tạo audio từ text và upload lên Cloud Storage
     *
     * @param text Text cần convert sang audio
     * @param languageCode Ngôn ngữ (mặc định: en-US)
     * @return Public URL của file audio
     */
    public String createAndUploadAudio(String text, String languageCode) {
        try {
            log.info("🎵 Creating audio for text: {}", text);

            // 1. Tạo audio bằng Google TTS
            byte[] audioBytes = generateAudio(text, languageCode);

            if (audioBytes == null || audioBytes.length == 0) {
                log.error("❌ Failed to generate audio");
                return null;
            }

            // 2. Upload lên Cloud Storage
            String audioUrl = uploadToCloudStorage(audioBytes, text);

            log.info("✅ Audio uploaded successfully: {}", audioUrl);
            return audioUrl;

        } catch (Exception e) {
            log.error("❌ Error creating and uploading audio: {}", e.getMessage());
            return null;
        }
    }

    /**
     * ✅ PUBLIC METHOD - Để TTS Controller có thể gọi
     * Tạo audio bytes để trả về trực tiếp cho frontend (không cần upload)
     */
    public byte[] generateAudioBytes(String text, String languageCode) {
        return generateAudio(text, languageCode);
    }

    /**
     * Tạo audio bằng Google Cloud Text-to-Speech API
     */
    private byte[] generateAudio(String text, String languageCode) {
        try {
            String url = ttsUrl + "?key=" + apiKey;

            // Tạo request body
            Map<String, Object> requestBody = new HashMap<>();

            Map<String, String> input = new HashMap<>();
            input.put("text", text);
            requestBody.put("input", input);

            Map<String, String> voice = new HashMap<>();
            voice.put("languageCode", languageCode != null ? languageCode : "en-US");
            voice.put("ssmlGender", "NEUTRAL");
            requestBody.put("voice", voice);

            Map<String, String> audioConfig = new HashMap<>();
            audioConfig.put("audioEncoding", "MP3");
            audioConfig.put("speakingRate", "0.9"); // Nói chậm hơn một chút để dễ nghe
            requestBody.put("audioConfig", audioConfig);

            // Headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

            // Gọi API
            ResponseEntity<String> response = restTemplate.exchange(
                    url,
                    HttpMethod.POST,
                    request,
                    String.class
            );

            if (response.getStatusCode() == HttpStatus.OK) {
                // Parse response để lấy audio content
                JsonNode root = objectMapper.readTree(response.getBody());
                String audioContent = root.path("audioContent").asText();

                if (audioContent != null && !audioContent.isEmpty()) {
                    return Base64.getDecoder().decode(audioContent);
                }
            }

            return null;

        } catch (Exception e) {
            log.error("❌ Error generating audio: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Upload file lên Google Cloud Storage
     *
     * Note: Để đơn giản, có thể sử dụng các phương án thay thế:
     * 1. Firebase Storage (dễ hơn, có SDK)
     * 2. AWS S3
     * 3. Cloudinary
     * 4. Lưu local và serve qua static folder
     */
    private String uploadToCloudStorage(byte[] audioBytes, String text) {
        try {
            // Tạo tên file unique
            String fileName = "tts_" + UUID.randomUUID().toString() + ".mp3";

            // lưu local

            String localUrl = saveLocalAndGetUrl(audioBytes, fileName);

            return localUrl;

        } catch (Exception e) {
            log.error("❌ Error uploading to cloud storage: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Lưu file local và trả về URL
     * (Phương án tạm thời cho development)
     */
    private String saveLocalAndGetUrl(byte[] audioBytes, String fileName) {
        try {
            // TODO: Implement save to local static folder
            // Example:
            // Path path = Paths.get("src/main/resources/static/audio/" + fileName);
            // Files.write(path, audioBytes);

            // Return URL
            String baseUrl = "http://localhost:8080/audio/"; // Adjust based on your setup
            return baseUrl + fileName;

        } catch (Exception e) {
            log.error("❌ Error saving file locally: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Kiểm tra xem service có được cấu hình đúng chưa
     */
    public boolean isConfigured() {
        return apiKey != null && !apiKey.isEmpty() && !apiKey.equals("AIzaSyByuLpzz3HjcL4NZO-H4_kSdtq0BThA6n8");
    }

    /**
     * Alternative: Sử dụng Web Speech API (client-side)
     * hoặc các TTS service khác như:
     * - Amazon Polly
     * - Microsoft Azure Speech
     * - ElevenLabs
     */
}