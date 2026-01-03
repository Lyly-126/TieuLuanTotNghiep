package com.tieuluan.backend.service;

import com.google.cloud.vision.v1.*;
import com.google.protobuf.ByteString;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Service trích xuất văn bản từ ảnh (OCR) và PDF
 *
 * Sử dụng:
 * - Google Cloud Vision API cho OCR
 * - Apache PDFBox cho PDF extraction
 *
 * Flow:
 * 1. Upload ảnh/PDF → Trích xuất text
 * 2. Phân tích text → Tách thành danh sách từ vựng
 * 3. Lọc và validate từ → Trả về danh sách từ hợp lệ
 *
 * ✅ UPDATED: Thêm partOfSpeechVi và definition khi trích xuất từ OCR/PDF
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TextExtractionService {

    private final DictionaryService dictionaryService;

    @Value("${google.cloud.vision.enabled:true}")
    private boolean visionEnabled;

    // ==================== OCR - IMAGE EXTRACTION ====================

    /**
     * Trích xuất text từ ảnh sử dụng Google Vision API
     */
    public TextExtractionResult extractFromImage(MultipartFile imageFile) {
        log.info("📷 Extracting text from image: {}", imageFile.getOriginalFilename());

        TextExtractionResult result = new TextExtractionResult();
        result.setSourceType("IMAGE");
        result.setFileName(imageFile.getOriginalFilename());

        try {
            // Validate file
            if (imageFile.isEmpty()) {
                throw new IllegalArgumentException("File ảnh trống");
            }

            String contentType = imageFile.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                throw new IllegalArgumentException("File không phải là ảnh hợp lệ");
            }

            // Check file size (max 10MB)
            if (imageFile.getSize() > 10 * 1024 * 1024) {
                throw new IllegalArgumentException("File ảnh quá lớn (tối đa 10MB)");
            }

            // Extract text using Vision API
            String rawText = performOCR(imageFile.getBytes());
            result.setRawText(rawText);

            // Parse words from text
            List<ExtractedWord> words = parseWordsFromText(rawText);
            result.setExtractedWords(words);
            result.setTotalWordsFound(words.size());

            result.setSuccess(true);
            result.setMessage("Đã trích xuất " + words.size() + " từ vựng từ ảnh");

            log.info("✅ OCR completed: {} words extracted", words.size());
            return result;

        } catch (Exception e) {
            log.error("❌ OCR failed: {}", e.getMessage(), e);
            result.setSuccess(false);
            result.setMessage("Lỗi OCR: " + e.getMessage());
            return result;
        }
    }

    /**
     * Thực hiện OCR bằng Google Vision API
     */
    private String performOCR(byte[] imageBytes) throws IOException {
        if (!visionEnabled) {
            log.warn("⚠️ Vision API disabled, using mock OCR");
            return mockOCR();
        }

        try (ImageAnnotatorClient vision = ImageAnnotatorClient.create()) {
            ByteString imgBytes = ByteString.copyFrom(imageBytes);

            Image img = Image.newBuilder()
                    .setContent(imgBytes)
                    .build();

            Feature feature = Feature.newBuilder()
                    .setType(Feature.Type.DOCUMENT_TEXT_DETECTION)
                    .build();

            AnnotateImageRequest request = AnnotateImageRequest.newBuilder()
                    .addFeatures(feature)
                    .setImage(img)
                    .build();

            List<AnnotateImageRequest> requests = Collections.singletonList(request);
            BatchAnnotateImagesResponse response = vision.batchAnnotateImages(requests);
            List<AnnotateImageResponse> responses = response.getResponsesList();

            if (responses.isEmpty()) {
                throw new RuntimeException("Không nhận được response từ Vision API");
            }

            AnnotateImageResponse res = responses.get(0);
            if (res.hasError()) {
                throw new RuntimeException("Vision API error: " + res.getError().getMessage());
            }

            TextAnnotation annotation = res.getFullTextAnnotation();
            return annotation.getText();
        } catch (IOException e) {
            // Kiểm tra nếu là lỗi credentials
            if (e.getMessage() != null && e.getMessage().contains("credentials")) {
                log.error("❌ Google Cloud credentials not configured");
                throw new IOException("Chưa cấu hình Google Cloud Vision API. Vui lòng liên hệ admin hoặc sử dụng tính năng đọc PDF thay thế.");
            }
            throw e;
        }
    }

    /**
     * Mock OCR cho testing khi không có Vision API
     */
    private String mockOCR() {
        return "Hello world\nApple banana\nComputer science\nBeautiful garden\nHappy birthday";
    }

    // ==================== PDF EXTRACTION ====================

    /**
     * Trích xuất text từ file PDF
     */
    public TextExtractionResult extractFromPDF(MultipartFile pdfFile) {
        log.info("📄 Extracting text from PDF: {}", pdfFile.getOriginalFilename());

        TextExtractionResult result = new TextExtractionResult();
        result.setSourceType("PDF");
        result.setFileName(pdfFile.getOriginalFilename());

        try {
            // Validate file
            if (pdfFile.isEmpty()) {
                throw new IllegalArgumentException("File PDF trống");
            }

            String contentType = pdfFile.getContentType();
            if (contentType == null || !contentType.equals("application/pdf")) {
                throw new IllegalArgumentException("File không phải là PDF hợp lệ");
            }

            // Check file size (max 20MB)
            if (pdfFile.getSize() > 20 * 1024 * 1024) {
                throw new IllegalArgumentException("File PDF quá lớn (tối đa 20MB)");
            }

            // Extract text using PDFBox
            String rawText = extractTextFromPDF(pdfFile.getBytes());
            result.setRawText(rawText);

            // Parse words from text
            List<ExtractedWord> words = parseWordsFromText(rawText);
            result.setExtractedWords(words);
            result.setTotalWordsFound(words.size());

            result.setSuccess(true);
            result.setMessage("Đã trích xuất " + words.size() + " từ vựng từ PDF");

            log.info("✅ PDF extraction completed: {} words extracted", words.size());
            return result;

        } catch (Exception e) {
            log.error("❌ PDF extraction failed: {}", e.getMessage(), e);
            result.setSuccess(false);
            result.setMessage("Lỗi đọc PDF: " + e.getMessage());
            return result;
        }
    }

    /**
     * Đọc text từ PDF sử dụng Apache PDFBox
     * Sử dụng Loader.loadPDF() cho PDFBox 3.x
     */
    private String extractTextFromPDF(byte[] pdfBytes) throws IOException {
        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            PDFTextStripper stripper = new PDFTextStripper();
            stripper.setSortByPosition(true);
            return stripper.getText(document);
        }
    }

    // ==================== TEXT PARSING ====================

    /**
     * Phân tích text và trích xuất danh sách từ vựng tiếng Anh
     *
     * ✅ UPDATED: Thêm partOfSpeechVi và definition khi tra từ điển
     */
    private List<ExtractedWord> parseWordsFromText(String rawText) {
        if (rawText == null || rawText.isEmpty()) {
            return Collections.emptyList();
        }

        // Patterns để tìm từ tiếng Anh
        // Pattern 1: Từ đơn thuần túy (a-z, có thể có - hoặc ')
        Pattern wordPattern = Pattern.compile("\\b([a-zA-Z][a-zA-Z'-]*[a-zA-Z]|[a-zA-Z])\\b");

        Set<String> foundWords = new LinkedHashSet<>(); // Giữ thứ tự, loại bỏ trùng lặp
        Matcher matcher = wordPattern.matcher(rawText.toLowerCase());

        while (matcher.find()) {
            String word = matcher.group(1).toLowerCase().trim();

            // Validate từ
            if (isValidEnglishWord(word)) {
                foundWords.add(word);
            }
        }

        // Chuyển thành ExtractedWord với thông tin từ dictionary
        List<ExtractedWord> result = new ArrayList<>();
        for (String word : foundWords) {
            ExtractedWord extracted = new ExtractedWord();
            extracted.setWord(word);

            // Kiểm tra trong dictionary
            try {
                var dictResult = dictionaryService.lookup(word);
                if (dictResult.isFound()) {
                    extracted.setFoundInDictionary(true);
                    extracted.setPartOfSpeech(dictResult.getPartOfSpeech());
                    // ✅ FIX: Thêm partOfSpeechVi
                    extracted.setPartOfSpeechVi(dictResult.getPartOfSpeechVi());
                    extracted.setMeaning(dictResult.getMeanings());
                    extracted.setPhonetic(dictResult.getPhonetic());
                    // ✅ FIX: Thêm definition (tiếng Anh)
                    extracted.setDefinition(dictResult.getDefinitions());

                    log.debug("✅ Word '{}': partOfSpeech={}, partOfSpeechVi={}",
                            word, dictResult.getPartOfSpeech(), dictResult.getPartOfSpeechVi());
                } else {
                    extracted.setFoundInDictionary(false);
                }
            } catch (Exception e) {
                log.debug("Dictionary lookup failed for '{}': {}", word, e.getMessage());
                extracted.setFoundInDictionary(false);
            }

            result.add(extracted);
        }

        // Sắp xếp: từ có trong dictionary lên trước
        result.sort((a, b) -> {
            if (a.isFoundInDictionary() && !b.isFoundInDictionary()) return -1;
            if (!a.isFoundInDictionary() && b.isFoundInDictionary()) return 1;
            return a.getWord().compareTo(b.getWord());
        });

        log.info("📊 Parsed {} words, {} found in dictionary",
                result.size(),
                result.stream().filter(ExtractedWord::isFoundInDictionary).count());

        return result;
    }

    /**
     * Kiểm tra xem từ có phải là từ tiếng Anh hợp lệ không
     */
    private boolean isValidEnglishWord(String word) {
        if (word == null || word.isEmpty()) return false;

        // Độ dài hợp lý (2-25 ký tự)
        if (word.length() < 2 || word.length() > 25) return false;

        // Không chứa số
        if (word.matches(".*\\d.*")) return false;

        // Không phải chỉ toàn là chữ viết hoa (có thể là viết tắt)
        if (word.equals(word.toUpperCase()) && word.length() > 2) return false;

        // Loại bỏ các từ quá phổ biến (stop words)
        // Sử dụng HashSet để tránh lỗi duplicate khi dùng Set.of()
        Set<String> stopWords = new HashSet<>(Arrays.asList(
                "a", "an", "the", "is", "am", "are", "was", "were", "be", "been", "being",
                "have", "has", "had", "do", "does", "did", "will", "would", "could", "should",
                "may", "might", "must", "shall", "can", "need", "dare", "ought", "used",
                "to", "of", "in", "for", "on", "with", "at", "by", "from", "as", "into",
                "through", "during", "before", "after", "above", "below", "between", "under",
                "again", "further", "then", "once", "here", "there", "when", "where", "why",
                "how", "all", "each", "every", "both", "few", "more", "most", "other",
                "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than",
                "too", "very", "just", "also", "now", "i", "me", "my", "we", "our",
                "you", "your", "he", "him", "his", "she", "her", "it", "its", "they",
                "them", "their", "this", "that", "these", "those", "what", "which", "who",
                "whom", "and", "but", "if", "or", "because", "until", "while", "although",
                "though", "even", "since", "about", "etc"
        ));

        return !stopWords.contains(word.toLowerCase());
    }

    // ==================== BATCH PREVIEW ====================

    /**
     * Preview nhiều từ cùng lúc (dùng cho OCR/PDF results)
     */
    public BatchPreviewResult batchPreviewWords(List<String> words) {
        log.info("🔍 Batch preview for {} words", words.size());

        BatchPreviewResult result = new BatchPreviewResult();
        result.setTotalWords(words.size());

        List<ExtractedWord> previews = new ArrayList<>();
        int foundCount = 0;
        int notFoundCount = 0;

        for (String word : words) {
            if (word == null || word.trim().isEmpty()) continue;

            ExtractedWord preview = new ExtractedWord();
            preview.setWord(word.trim().toLowerCase());

            try {
                var dictResult = dictionaryService.lookup(word.trim());
                if (dictResult.isFound()) {
                    preview.setFoundInDictionary(true);
                    preview.setPartOfSpeech(dictResult.getPartOfSpeech());
                    preview.setPartOfSpeechVi(dictResult.getPartOfSpeechVi());
                    preview.setMeaning(dictResult.getMeanings());
                    preview.setPhonetic(dictResult.getPhonetic());
                    preview.setDefinition(dictResult.getDefinitions());
                    foundCount++;
                } else {
                    preview.setFoundInDictionary(false);
                    notFoundCount++;
                }
            } catch (Exception e) {
                log.debug("Lookup failed for '{}': {}", word, e.getMessage());
                preview.setFoundInDictionary(false);
                notFoundCount++;
            }

            previews.add(preview);
        }

        result.setWords(previews);
        result.setFoundInDictionary(foundCount);
        result.setNotFoundInDictionary(notFoundCount);
        result.setSuccess(true);

        log.info("✅ Batch preview complete: {}/{} found in dictionary", foundCount, words.size());
        return result;
    }

    // ==================== DTOs ====================

    @Data
    public static class TextExtractionResult {
        private boolean success;
        private String message;
        private String sourceType; // IMAGE or PDF
        private String fileName;
        private String rawText;
        private int totalWordsFound;
        private List<ExtractedWord> extractedWords;
    }

    @Data
    public static class ExtractedWord {
        private String word;
        private boolean foundInDictionary;
        private String partOfSpeech;
        private String partOfSpeechVi;    // ✅ Đã có field này
        private String meaning;
        private String phonetic;
        private String definition;        // ✅ Đã có field này
        private boolean selected = false; // Cho UI chọn
    }

    @Data
    public static class BatchPreviewResult {
        private boolean success;
        private int totalWords;
        private int foundInDictionary;
        private int notFoundInDictionary;
        private List<ExtractedWord> words;
    }
}