import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'flashcard_creation_service.dart';

/// Service cho tính năng OCR và PDF extraction
///
/// Flow sử dụng:
/// 1. extractFromImage() hoặc extractFromPDF() → Lấy danh sách từ
/// 2. User chọn từ cần tạo flashcard
/// 3. previewSelectedWords() → Preview chi tiết
/// 4. suggestCategoryForBatch() → Gợi ý category
/// 5. createFlashcardsBatch() → Tạo flashcard hàng loạt
class TextExtractionService {
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
        throw Exception(error['message'] ?? 'OCR failed: ${response.statusCode}');
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
        throw Exception(error['message'] ?? 'OCR failed');
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
        throw Exception(error['message'] ?? 'PDF extraction failed');
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
        throw Exception(error['message'] ?? 'PDF extraction failed');
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
          'partOfSpeechVi': w.partOfSpeechVi,
          'meaning': w.meaning,
          'phonetic': w.phonetic,
          'definition': w.definition,
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

/// Category được gợi ý (định nghĩa local để tránh conflict với import)
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