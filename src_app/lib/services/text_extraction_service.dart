import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import 'flashcard_creation_service.dart';

/// Service cho tính năng OCR và PDF extraction
///
/// ✅ UPDATED:
/// - Thêm tải PDF template từ app
/// - Thêm kiểm tra giới hạn (100 từ)
/// - Thêm validation PDF template
///
/// Flow sử dụng:
/// 1. downloadPdfTemplate() → Tải mẫu PDF
/// 2. User điền từ vựng vào mẫu
/// 3. extractFromPDF() → Upload và trích xuất
/// 4. User chọn từ cần tạo flashcard
/// 5. createFlashcardsBatch() → Tạo flashcard hàng loạt
class TextExtractionService {
  /// Giới hạn số từ vựng tối đa
  static const int maxWordsLimit = 100;

  /// Lấy token từ SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Headers với authentication
  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Headers cho JSON request
  static Future<Map<String, String>> _getJsonHeaders() async {
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';
    return headers;
  }

  // ==================== PDF TEMPLATE ====================

  /// Tải PDF template từ server
  ///
  /// [templateType] - Loại template: 'BASIC' hoặc 'ADVANCED'
  /// Returns: Đường dẫn đến file PDF đã tải
  static Future<PdfTemplateResult> downloadPdfTemplate({
    String templateType = 'BASIC',
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/template?type=$templateType';
      print('📥 Downloading PDF template: $url');

      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Lưu file PDF vào thư mục tạm
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/flashcard_template.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        print('✅ PDF template saved to: $filePath');

        return PdfTemplateResult(
          success: true,
          filePath: filePath,
          message: 'Đã tải mẫu PDF thành công',
        );
      } else {
        throw Exception('Failed to download template: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Download template error: $e');
      return PdfTemplateResult(
        success: false,
        message: 'Lỗi tải mẫu PDF: $e',
      );
    }
  }

  /// Lấy thông tin giới hạn của tính năng
  static Future<ExtractionLimits> getExtractionLimits() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/limits';
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExtractionLimits.fromJson(data);
      } else {
        // Trả về giá trị mặc định nếu API lỗi
        return ExtractionLimits.defaultLimits();
      }
    } catch (e) {
      print('❌ Get limits error: $e');
      return ExtractionLimits.defaultLimits();
    }
  }

  // ==================== OCR - EXTRACT FROM IMAGE ====================

  /// Trích xuất từ vựng từ ảnh
  ///
  /// [imageFile] - File ảnh (jpg, png, etc.)
  /// Returns: TextExtractionResult với danh sách từ
  static Future<TextExtractionResult> extractFromImage(File imageFile) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/ocr';
      print('📷 OCR: POST $url');

      final headers = await _getHeaders();

      // Tạo multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      // Thêm file
      final fileName = imageFile.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ));

      // Gửi request
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      print('📥 OCR Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TextExtractionResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TextExtractionResult(
          success: false,
          message: error['message'] ?? 'OCR failed: ${response.statusCode}',
          sourceType: 'IMAGE',
          extractedWords: [],
        );
      }
    } catch (e) {
      print('❌ OCR error: $e');
      return TextExtractionResult(
        success: false,
        message: 'Lỗi OCR: $e',
        sourceType: 'IMAGE',
        extractedWords: [],
      );
    }
  }

  /// Trích xuất từ vựng từ ảnh bytes (cho web)
  static Future<TextExtractionResult> extractFromImageBytes(
      List<int> imageBytes,
      String fileName,
      ) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/ocr';
      print('📷 OCR (bytes): POST $url');

      final headers = await _getHeaders();

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      final extension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ));

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TextExtractionResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TextExtractionResult(
          success: false,
          message: error['message'] ?? 'OCR failed',
          sourceType: 'IMAGE',
          extractedWords: [],
        );
      }
    } catch (e) {
      print('❌ OCR (bytes) error: $e');
      return TextExtractionResult(
        success: false,
        message: 'Lỗi OCR: $e',
        sourceType: 'IMAGE',
        extractedWords: [],
      );
    }
  }

  // ==================== PDF EXTRACTION ====================

  /// Trích xuất từ vựng từ PDF
  ///
  /// ⚠️ CHÚ Ý: Chỉ hỗ trợ PDF được tạo từ mẫu của ứng dụng
  static Future<TextExtractionResult> extractFromPDF(File pdfFile) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/pdf';
      print('📄 PDF: POST $url');

      final headers = await _getHeaders();

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        pdfFile.path,
        contentType: MediaType.parse('application/pdf'),
      ));

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      print('📥 PDF Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TextExtractionResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TextExtractionResult(
          success: false,
          message: error['message'] ?? 'PDF extraction failed',
          sourceType: 'PDF',
          extractedWords: [],
        );
      }
    } catch (e) {
      print('❌ PDF error: $e');
      return TextExtractionResult(
        success: false,
        message: 'Lỗi đọc PDF: $e',
        sourceType: 'PDF',
        extractedWords: [],
      );
    }
  }

  /// Trích xuất từ vựng từ PDF bytes (cho web)
  ///
  /// ⚠️ CHÚ Ý: Chỉ hỗ trợ PDF được tạo từ mẫu của ứng dụng
  static Future<TextExtractionResult> extractFromPDFBytes(
      List<int> pdfBytes,
      String fileName,
      ) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/pdf';
      print('📄 PDF (bytes): POST $url');

      final headers = await _getHeaders();

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        pdfBytes,
        filename: fileName,
        contentType: MediaType.parse('application/pdf'),
      ));

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TextExtractionResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        return TextExtractionResult(
          success: false,
          message: error['message'] ?? 'PDF extraction failed',
          sourceType: 'PDF',
          extractedWords: [],
        );
      }
    } catch (e) {
      print('❌ PDF (bytes) error: $e');
      return TextExtractionResult(
        success: false,
        message: 'Lỗi đọc PDF: $e',
        sourceType: 'PDF',
        extractedWords: [],
      );
    }
  }

  // ==================== PREVIEW SELECTED WORDS ====================

  /// Preview chi tiết cho danh sách từ đã chọn
  static Future<BatchPreviewResult> previewSelectedWords(List<String> words) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/preview';
      print('🔍 Preview: POST $url');

      final headers = await _getJsonHeaders();

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'words': words}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BatchPreviewResult.fromJson(data);
      } else {
        throw Exception('Preview failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Preview error: $e');
      rethrow;
    }
  }

  // ==================== SUGGEST CATEGORY ====================

  /// Gợi ý category cho batch từ vựng
  static Future<BatchCategorySuggestionResult> suggestCategoryForBatch(
      List<ExtractedWord> words,
      ) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/suggest-category';
      print('🏷️ Suggest category: POST $url');

      final headers = await _getJsonHeaders();

      final wordInfoList = words.map((w) {
        return {
          'word': w.word,
          'partOfSpeech': w.partOfSpeech,
          'meaning': w.meaning,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'words': wordInfoList}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BatchCategorySuggestionResult.fromJson(data);
      } else {
        throw Exception('Suggest category failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Suggest category error: $e');
      rethrow;
    }
  }

  // ==================== CREATE FLASHCARDS BATCH ====================

  /// Tạo flashcard hàng loạt từ danh sách từ đã chọn
  static Future<BatchCreateResult> createFlashcardsBatch({
    required List<ExtractedWord> words,
    required int categoryId,
    bool generateAudio = true,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/text-extraction/create-batch';
      print('📚 Batch create: POST $url');

      final headers = await _getJsonHeaders();

      final wordInfoList = words.map((w) {
        return {
          'word': w.word,
          'partOfSpeech': w.partOfSpeech,
          'partOfSpeechVi': w.partOfSpeechVi,
          'meaning': w.meaning,
          'phonetic': w.phonetic,
          'definition': w.definition,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'words': wordInfoList,
          'categoryId': categoryId,
          'generateAudio': generateAudio,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BatchCreateResult.fromJson(data);
      } else {
        throw Exception('Batch create failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Batch create error: $e');
      rethrow;
    }
  }

  // ==================== HELPERS ====================

  static String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }
}

// ==================== DTOs ====================

/// Kết quả tải PDF template
class PdfTemplateResult {
  final bool success;
  final String? filePath;
  final String? message;

  PdfTemplateResult({
    required this.success,
    this.filePath,
    this.message,
  });
}

/// Thông tin giới hạn của tính năng extraction
class ExtractionLimits {
  final int maxWordsPerExtraction;
  final int maxImageSizeMB;
  final int maxPdfSizeMB;
  final List<String> supportedImageFormats;
  final bool pdfTemplateRequired;
  final String? message;

  ExtractionLimits({
    required this.maxWordsPerExtraction,
    required this.maxImageSizeMB,
    required this.maxPdfSizeMB,
    required this.supportedImageFormats,
    required this.pdfTemplateRequired,
    this.message,
  });

  factory ExtractionLimits.fromJson(Map<String, dynamic> json) {
    return ExtractionLimits(
      maxWordsPerExtraction: json['maxWordsPerExtraction'] ?? 100,
      maxImageSizeMB: json['maxImageSizeMB'] ?? 10,
      maxPdfSizeMB: json['maxPdfSizeMB'] ?? 20,
      supportedImageFormats: (json['supportedImageFormats'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? ['jpg', 'jpeg', 'png'],
      pdfTemplateRequired: json['pdfTemplateRequired'] ?? true,
      message: json['message'],
    );
  }

  factory ExtractionLimits.defaultLimits() {
    return ExtractionLimits(
      maxWordsPerExtraction: 100,
      maxImageSizeMB: 10,
      maxPdfSizeMB: 20,
      supportedImageFormats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
      pdfTemplateRequired: true,
      message: 'Chỉ hỗ trợ PDF từ mẫu của ứng dụng. Tối đa 100 từ.',
    );
  }
}

/// Kết quả trích xuất text từ ảnh/PDF
class TextExtractionResult {
  final bool success;
  final String? message;
  final String? sourceType;
  final String? fileName;
  final String? rawText;
  final int totalWordsFound;
  final List<ExtractedWord> extractedWords;

  TextExtractionResult({
    required this.success,
    this.message,
    this.sourceType,
    this.fileName,
    this.rawText,
    this.totalWordsFound = 0,
    required this.extractedWords,
  });

  factory TextExtractionResult.fromJson(Map<String, dynamic> json) {
    return TextExtractionResult(
      success: json['success'] ?? false,
      message: json['message'],
      sourceType: json['sourceType'],
      fileName: json['fileName'],
      rawText: json['rawText'],
      totalWordsFound: json['totalWordsFound'] ?? 0,
      extractedWords: (json['extractedWords'] as List<dynamic>?)
          ?.map((e) => ExtractedWord.fromJson(e))
          .toList() ?? [],
    );
  }
}

/// Từ vựng được trích xuất
class ExtractedWord {
  String word;
  bool foundInDictionary;
  String? partOfSpeech;
  String? partOfSpeechVi;
  String? meaning;
  String? phonetic;
  String? definition;
  bool selected;

  ExtractedWord({
    required this.word,
    this.foundInDictionary = false,
    this.partOfSpeech,
    this.partOfSpeechVi,
    this.meaning,
    this.phonetic,
    this.definition,
    this.selected = false,
  });

  factory ExtractedWord.fromJson(Map<String, dynamic> json) {
    return ExtractedWord(
      word: json['word'] ?? '',
      foundInDictionary: json['foundInDictionary'] ?? false,
      partOfSpeech: json['partOfSpeech'],
      partOfSpeechVi: json['partOfSpeechVi'],
      meaning: json['meaning'],
      phonetic: json['phonetic'],
      definition: json['definition'],
      selected: json['selected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'foundInDictionary': foundInDictionary,
      'partOfSpeech': partOfSpeech,
      'partOfSpeechVi': partOfSpeechVi,
      'meaning': meaning,
      'phonetic': phonetic,
      'definition': definition,
      'selected': selected,
    };
  }

  /// Copy with selected state
  ExtractedWord copyWith({bool? selected}) {
    return ExtractedWord(
      word: word,
      foundInDictionary: foundInDictionary,
      partOfSpeech: partOfSpeech,
      partOfSpeechVi: partOfSpeechVi,
      meaning: meaning,
      phonetic: phonetic,
      definition: definition,
      selected: selected ?? this.selected,
    );
  }
}

/// Kết quả preview batch
class BatchPreviewResult {
  final bool success;
  final int totalWords;
  final int foundInDictionary;
  final int notFoundInDictionary;
  final List<ExtractedWord> words;

  BatchPreviewResult({
    required this.success,
    required this.totalWords,
    required this.foundInDictionary,
    required this.notFoundInDictionary,
    required this.words,
  });

  factory BatchPreviewResult.fromJson(Map<String, dynamic> json) {
    return BatchPreviewResult(
      success: json['success'] ?? false,
      totalWords: json['totalWords'] ?? 0,
      foundInDictionary: json['foundInDictionary'] ?? 0,
      notFoundInDictionary: json['notFoundInDictionary'] ?? 0,
      words: (json['words'] as List<dynamic>?)
          ?.map((e) => ExtractedWord.fromJson(e))
          .toList() ?? [],
    );
  }
}

/// Kết quả gợi ý category cho batch
class BatchCategorySuggestionResult {
  final bool success;
  final String? message;
  final int totalWordsAnalyzed;
  final List<CategorySuggestionItem> suggestions;
  final List<CategorySuggestionItem> userCategories;

  BatchCategorySuggestionResult({
    required this.success,
    this.message,
    this.totalWordsAnalyzed = 0,
    required this.suggestions,
    required this.userCategories,
  });

  factory BatchCategorySuggestionResult.fromJson(Map<String, dynamic> json) {
    return BatchCategorySuggestionResult(
      success: json['success'] ?? false,
      message: json['message'],
      totalWordsAnalyzed: json['totalWordsAnalyzed'] ?? 0,
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((e) => CategorySuggestionItem.fromJson(e))
          .toList() ?? [],
      userCategories: (json['userCategories'] as List<dynamic>?)
          ?.map((e) => CategorySuggestionItem.fromJson(e))
          .toList() ?? [],
    );
  }
}

/// Category được gợi ý
class CategorySuggestionItem {
  final int? categoryId;
  final String? categoryName;
  final String? description;
  final double? confidenceScore;
  final String? reason;

  CategorySuggestionItem({
    this.categoryId,
    this.categoryName,
    this.description,
    this.confidenceScore,
    this.reason,
  });

  factory CategorySuggestionItem.fromJson(Map<String, dynamic> json) {
    return CategorySuggestionItem(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      description: json['description'],
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      reason: json['reason'],
    );
  }
}