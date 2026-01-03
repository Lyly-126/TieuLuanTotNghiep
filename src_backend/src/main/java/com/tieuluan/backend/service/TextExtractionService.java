package com.tieuluan.backend.service;

import com.google.cloud.vision.v1.*;
import com.google.protobuf.ByteString;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Service trích xuất văn bản từ ảnh (OCR) và PDF
 *
 * ✅ UPDATED v3:
 * - Validate PDF phải có marker FLASHCARD_APP_TEMPLATE_V1
 * - Giới hạn tối đa 100 từ vựng mỗi lần trích xuất
 * - Kiểm tra marker trong metadata và content
 * - Fix PDFBox 3.x font API
 * - Fix duplicate method
 *
 * Flow:
 * 1. Upload ảnh/PDF → Validate (PDF cần marker)
 * 2. Trích xuất text → Parse thành danh sách từ
 * 3. Giới hạn 100 từ → Trả về kết quả
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TextExtractionService {

    private final DictionaryService dictionaryService;

    @Value("${google.cloud.vision.enabled:true}")
    private boolean visionEnabled;

    // ==================== CONSTANTS ====================

    /**
     * Marker để nhận diện PDF được tạo từ app
     * PDF phải chứa marker này trong metadata hoặc content
     */
    private static final String APP_PDF_MARKER = "FLASHCARD_APP_TEMPLATE_V1";

    /**
     * Giới hạn số từ vựng tối đa mỗi lần trích xuất
     */
    private static final int MAX_WORDS_LIMIT = 100;

    // ==================== OCR - IMAGE EXTRACTION ====================

    /**
     * Trích xuất text từ ảnh sử dụng Google Vision API
     * ✅ Áp dụng giới hạn 100 từ
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

            // ✅ Kiểm tra giới hạn 100 từ
            if (words.size() > MAX_WORDS_LIMIT) {
                log.warn("⚠️ Image contains {} words, exceeds limit of {}", words.size(), MAX_WORDS_LIMIT);
                result.setSuccess(false);
                result.setMessage("Ảnh chứa " + words.size() + " từ vựng, vượt quá giới hạn " + MAX_WORDS_LIMIT + " từ. Vui lòng sử dụng ảnh có ít từ hơn.");
                result.setTotalWordsFound(words.size());
                return result;
            }

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
     *
     * ✅ UPDATED:
     * - Validate PDF phải có marker FLASHCARD_APP_TEMPLATE_V1
     * - Giới hạn tối đa 100 từ
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

            byte[] pdfBytes = pdfFile.getBytes();

            // ✅ VALIDATE: Kiểm tra PDF có marker không
            if (!validateAppPdfTemplate(pdfBytes)) {
                log.warn("❌ PDF does not contain app marker: {}", pdfFile.getOriginalFilename());
                result.setSuccess(false);
                result.setMessage("Chỉ hỗ trợ PDF được tạo từ mẫu của ứng dụng Flai. " +
                        "Vui lòng sử dụng tính năng 'Tạo PDF' trong app để tạo mẫu PDF, " +
                        "hoặc sử dụng tính năng chụp ảnh để trích xuất từ vựng.");
                return result;
            }

            log.info("✅ PDF marker validated successfully");

            // Extract text using PDFBox
            String rawText = extractTextFromPDF(pdfBytes);
            result.setRawText(rawText);

            // Parse words from text
            List<ExtractedWord> words = parseWordsFromText(rawText);

            // ✅ Kiểm tra giới hạn 100 từ
            if (words.size() > MAX_WORDS_LIMIT) {
                log.warn("⚠️ PDF contains {} words, exceeds limit of {}", words.size(), MAX_WORDS_LIMIT);
                result.setSuccess(false);
                result.setMessage("PDF chứa " + words.size() + " từ vựng, vượt quá giới hạn " + MAX_WORDS_LIMIT + " từ. " +
                        "Vui lòng sử dụng file PDF nhỏ hơn.");
                result.setTotalWordsFound(words.size());
                return result;
            }

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
     * Validate PDF có phải được tạo từ app không
     *
     * Kiểm tra marker trong:
     * 1. Metadata (Subject, Keywords, Author, Creator)
     * 2. Content của trang đầu tiên (backup)
     *
     * @param pdfBytes byte array của PDF
     * @return true nếu PDF hợp lệ (có marker)
     */
    private boolean validateAppPdfTemplate(byte[] pdfBytes) {
        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            // 1. Kiểm tra trong metadata
            PDDocumentInformation info = document.getDocumentInformation();

            if (info != null) {
                // Check Subject
                String subject = info.getSubject();
                if (subject != null && subject.contains(APP_PDF_MARKER)) {
                    log.debug("✅ Found marker in PDF Subject metadata");
                    return true;
                }

                // Check Keywords
                String keywords = info.getKeywords();
                if (keywords != null && keywords.contains(APP_PDF_MARKER)) {
                    log.debug("✅ Found marker in PDF Keywords metadata");
                    return true;
                }

                // Check Author (FlashcardApp)
                String author = info.getAuthor();
                if (author != null && author.contains("FlashcardApp")) {
                    log.debug("✅ Found FlashcardApp in PDF Author metadata");
                    return true;
                }

                // Check Creator
                String creator = info.getCreator();
                if (creator != null && creator.contains("FlashcardApp")) {
                    log.debug("✅ Found FlashcardApp in PDF Creator metadata");
                    return true;
                }
            }

            // 2. Backup: Kiểm tra trong content của trang đầu
            PDFTextStripper stripper = new PDFTextStripper();
            stripper.setStartPage(1);
            stripper.setEndPage(1);
            String firstPageText = stripper.getText(document);

            if (firstPageText != null && firstPageText.contains(APP_PDF_MARKER)) {
                log.debug("✅ Found marker in PDF content (first page)");
                return true;
            }

            log.warn("❌ PDF marker not found in metadata or content");
            return false;

        } catch (IOException e) {
            log.error("❌ Error validating PDF: {}", e.getMessage());
            return false;
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
     */
    private List<ExtractedWord> parseWordsFromText(String rawText) {
        if (rawText == null || rawText.isEmpty()) {
            return Collections.emptyList();
        }

        // Pattern để tìm từ tiếng Anh
        Pattern wordPattern = Pattern.compile("\\b([a-zA-Z][a-zA-Z'-]*[a-zA-Z]|[a-zA-Z])\\b");

        Set<String> foundWords = new LinkedHashSet<>();
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
                    extracted.setPartOfSpeechVi(dictResult.getPartOfSpeechVi());
                    extracted.setMeaning(dictResult.getMeanings());
                    extracted.setPhonetic(dictResult.getPhonetic());
                    extracted.setDefinition(dictResult.getDefinitions());
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

    // ==================== PDF TEMPLATE GENERATION ====================

    /**
     * Tạo PDF template để user download và điền từ vựng
     *
     * ✅ PDF được tạo ra sẽ có marker FLASHCARD_APP_TEMPLATE_V1
     * để hệ thống có thể nhận diện khi upload lại
     *
     * ✅ FIX: Sử dụng PDFBox 3.x API cho fonts
     *
     * @param templateType loại template: "100words", "50words", "25words", "BASIC", etc.
     * @return byte[] của PDF
     */
    public byte[] generatePdfTemplate(String templateType) throws IOException {
        log.info("📄 Generating PDF template: type={}", templateType);

        // Xác định số từ dựa trên templateType
        int wordCount = 100; // Default
        if (templateType != null) {
            if (templateType.contains("50")) {
                wordCount = 50;
            } else if (templateType.contains("25")) {
                wordCount = 25;
            }
        }

        try {
            PDDocument document = new PDDocument();

            // Set metadata với marker
            PDDocumentInformation info = document.getDocumentInformation();
            info.setTitle("Vocabulary List - FlashcardApp Template");
            info.setAuthor("FlashcardApp");
            info.setCreator("FlashcardApp");
            info.setSubject(APP_PDF_MARKER);
            info.setKeywords(APP_PDF_MARKER + ", vocabulary, flashcard, template");

            // Tạo trang A4
            PDPage page = new PDPage(PDRectangle.A4);
            document.addPage(page);

            // ✅ FIX: PDFBox 3.x font API
            PDType1Font fontBold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDType1Font fontNormal = new PDType1Font(Standard14Fonts.FontName.HELVETICA);

            // Vẽ nội dung
            try (PDPageContentStream contentStream = new PDPageContentStream(document, page)) {

                float pageWidth = page.getMediaBox().getWidth();
                float pageHeight = page.getMediaBox().getHeight();
                float margin = 40;
                float contentWidth = pageWidth - 2 * margin;

                // ===== HEADER =====
                float yPosition = pageHeight - margin;

                // Title
                contentStream.beginText();
                contentStream.setFont(fontBold, 18);
                contentStream.newLineAtOffset(margin, yPosition - 20);
                contentStream.showText("MY VOCABULARY LIST");
                contentStream.endText();

                // Subtitle với marker (nhỏ, màu xám)
                contentStream.beginText();
                contentStream.setFont(fontNormal, 8);
                contentStream.setNonStrokingColor(0.6f, 0.6f, 0.6f);
                contentStream.newLineAtOffset(margin, yPosition - 35);
                contentStream.showText("Template ID: " + APP_PDF_MARKER);
                contentStream.endText();
                contentStream.setNonStrokingColor(0, 0, 0); // Reset to black

                // Date field
                contentStream.beginText();
                contentStream.setFont(fontNormal, 10);
                contentStream.newLineAtOffset(pageWidth - margin - 120, yPosition - 20);
                contentStream.showText("Date: ___/___/______");
                contentStream.endText();

                // Line separator
                yPosition -= 50;
                contentStream.setLineWidth(1);
                contentStream.moveTo(margin, yPosition);
                contentStream.lineTo(pageWidth - margin, yPosition);
                contentStream.stroke();

                // ===== GRID =====
                yPosition -= 15;
                float gridStartY = yPosition;

                // Tính số cột và hàng
                int cols = 10;
                int rows = wordCount / cols;

                float cellWidth = contentWidth / cols;
                float availableHeight = gridStartY - margin - 50; // Trừ footer space
                float cellHeight = availableHeight / rows;

                // Giới hạn cell size
                cellWidth = Math.min(cellWidth, 52);
                cellHeight = Math.min(cellHeight, 58);

                // Center grid
                float gridWidth = cellWidth * cols;
                float gridStartX = margin + (contentWidth - gridWidth) / 2;

                // Vẽ grid
                for (int row = 0; row < rows; row++) {
                    for (int col = 0; col < cols; col++) {
                        int cellNumber = row * cols + col + 1;
                        float x = gridStartX + col * cellWidth;
                        float y = gridStartY - row * cellHeight;

                        // Vẽ ô
                        contentStream.setStrokingColor(0.7f, 0.7f, 0.7f);
                        contentStream.setLineWidth(0.5f);
                        contentStream.addRect(x, y - cellHeight, cellWidth, cellHeight);
                        contentStream.stroke();

                        // Số thứ tự
                        contentStream.beginText();
                        contentStream.setFont(fontNormal, 6);
                        contentStream.setNonStrokingColor(0.5f, 0.5f, 0.5f);
                        contentStream.newLineAtOffset(x + 2, y - 8);
                        contentStream.showText(String.valueOf(cellNumber));
                        contentStream.endText();
                        contentStream.setNonStrokingColor(0, 0, 0);
                    }
                }

                // ===== FOOTER =====
                float footerY = margin + 35;

                // Instructions
                contentStream.beginText();
                contentStream.setFont(fontNormal, 8);
                contentStream.setNonStrokingColor(0.4f, 0.4f, 0.4f);
                contentStream.newLineAtOffset(margin, footerY);
                contentStream.showText("Instructions: Write one English word per cell. Maximum " + wordCount + " words.");
                contentStream.endText();

                contentStream.beginText();
                contentStream.newLineAtOffset(margin, footerY - 12);
                contentStream.showText("After filling, upload this PDF to FlashcardApp to create flashcards automatically.");
                contentStream.endText();

                // Footer branding
                contentStream.beginText();
                contentStream.setFont(fontNormal, 7);
                contentStream.newLineAtOffset(margin, margin + 5);
                contentStream.showText("Created with FlashcardApp - " + APP_PDF_MARKER);
                contentStream.endText();

                // Hidden marker (white text, invisible but readable by extractor)
                contentStream.beginText();
                contentStream.setFont(fontNormal, 1);
                contentStream.setNonStrokingColor(1, 1, 1);
                contentStream.newLineAtOffset(margin, margin);
                contentStream.showText(APP_PDF_MARKER);
                contentStream.endText();
            }

            // Convert to bytes
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            document.save(baos);
            document.close();

            byte[] pdfBytes = baos.toByteArray();
            log.info("✅ PDF template generated: {} bytes, {} words", pdfBytes.length, wordCount);

            return pdfBytes;

        } catch (Exception e) {
            log.error("❌ Failed to generate PDF template: {}", e.getMessage(), e);
            throw new IOException("Không thể tạo PDF template: " + e.getMessage(), e);
        }
    }

    // ==================== UTILITY METHODS ====================

    /**
     * Lấy thông tin giới hạn của service
     */
    public ExtractionLimits getExtractionLimits() {
        ExtractionLimits limits = new ExtractionLimits();
        limits.setMaxWordsPerExtraction(MAX_WORDS_LIMIT);
        limits.setMaxImageSizeMB(10);
        limits.setMaxPdfSizeMB(20);
        limits.setSupportedImageFormats(Arrays.asList("jpg", "jpeg", "png", "gif", "webp"));
        limits.setPdfMarkerRequired(true);
        limits.setPdfMarker(APP_PDF_MARKER);
        return limits;
    }

    // ==================== DTOs ====================

    @Data
    public static class TextExtractionResult {
        private boolean success;
        private String message;
        private String sourceType; // IMAGE, PDF, or MANUAL
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
        private String partOfSpeechVi;
        private String meaning;
        private String phonetic;
        private String definition;
        private boolean selected = false;
    }

    @Data
    public static class BatchPreviewResult {
        private boolean success;
        private int totalWords;
        private int foundInDictionary;
        private int notFoundInDictionary;
        private List<ExtractedWord> words;
    }

    @Data
    public static class ExtractionLimits {
        private int maxWordsPerExtraction;
        private int maxImageSizeMB;
        private int maxPdfSizeMB;
        private List<String> supportedImageFormats;
        private boolean pdfMarkerRequired;
        private String pdfMarker;
    }
}