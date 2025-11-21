package com.tieuluan.backend.controller;

import com.tieuluan.backend.service.GoogleCloudStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * REST Controller xử lý Text-to-Speech
 * Endpoint cho frontend gọi để lấy audio
 */
@Slf4j
@RestController
@RequestMapping("/api/tts")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class TTSController {

    private final GoogleCloudStorageService ttsService;

    /**
     * Endpoint tạo audio từ text và trả về audio file trực tiếp
     * Frontend sẽ gọi endpoint này khi cần phát âm
     *
     * @param text Text cần convert sang audio
     * @param languageCode Ngôn ngữ (mặc định: en-US)
     * @return Audio file (MP3) dưới dạng byte array
     */
    @PostMapping(value = "/generate-audio", produces = "audio/mpeg")
    public ResponseEntity<byte[]> generateAudio(
            @RequestParam String text,
            @RequestParam(defaultValue = "en-US") String languageCode
    ) {
        try {
            log.info("🎵 TTS Request - Text: {}, Language: {}", text, languageCode);

            // Gọi service để tạo audio
            byte[] audioBytes = ttsService.generateAudioBytes(text, languageCode);

            if (audioBytes == null || audioBytes.length == 0) {
                log.error("❌ Failed to generate audio");
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
            }

            // Trả về audio file
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("audio/mpeg"));
            headers.setContentLength(audioBytes.length);
            headers.set("Cache-Control", "public, max-age=3600"); // Cache 1 giờ

            log.info("✅ Audio generated successfully - Size: {} bytes", audioBytes.length);

            return ResponseEntity.ok()
                    .headers(headers)
                    .body(audioBytes);

        } catch (Exception e) {
            log.error("❌ Error generating audio: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Alternative endpoint: Trả về URL của audio đã upload
     * Sử dụng khi muốn cache audio trên cloud storage
     *
     * @param text Text cần convert sang audio
     * @param languageCode Ngôn ngữ (mặc định: en-US)
     * @return JSON với URL của audio file
     */
    @PostMapping("/generate-url")
    public ResponseEntity<Map<String, Object>> generateAudioUrl(
            @RequestParam String text,
            @RequestParam(defaultValue = "en-US") String languageCode
    ) {
        try {
            log.info("🎵 TTS URL Request - Text: {}", text);

            String audioUrl = ttsService.createAndUploadAudio(text, languageCode);

            Map<String, Object> response = new HashMap<>();
            if (audioUrl != null && !audioUrl.isEmpty()) {
                response.put("success", true);
                response.put("audioUrl", audioUrl);
                log.info("✅ Audio URL generated: {}", audioUrl);
            } else {
                response.put("success", false);
                response.put("message", "Failed to generate audio");
                log.error("❌ Audio URL generation failed");
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("❌ Error generating audio URL: {}", e.getMessage(), e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("service", "TTS Service");
        response.put("configured", ttsService.isConfigured());
        return ResponseEntity.ok(response);
    }
}