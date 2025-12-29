import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'dictionary_service.dart';
import 'image_suggestion_service.dart';
import 'category_suggestion_service.dart';

/// Service tạo Flashcard mới với flow:
/// 1. Preview: Tra từ điển + gợi ý ảnh
/// 2. Suggest Category: AI phân loại
/// 3. Create: Lưu flashcard
class FlashcardCreationService {

  /// ========================================
  /// STEP 1: Preview flashcard
  /// ========================================
  /// Tra từ điển + lấy gợi ý 5 ảnh
  static Future<FlashcardPreviewResult> preview(String term) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/flashcard-creation/preview');

      print('📝 Preview flashcard for: $term');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'term': term}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FlashcardPreviewResult.fromJson(data);
      } else {
        throw Exception('Failed to preview: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Preview error: $e');
      rethrow;
    }
  }

  /// Preview qua GET
  static Future<FlashcardPreviewResult> previewGet(String term) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/flashcard-creation/preview')
          .replace(queryParameters: {'term': term});

      final response = await http.get(uri, headers: {
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FlashcardPreviewResult.fromJson(data);
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Preview error: $e');
      rethrow;
    }
  }

  /// ========================================
  /// STEP 2: Suggest category
  /// ========================================
  static Future<CategorySuggestionResult> suggestCategory({
    required String term,
    String? meaning,
    String? partOfSpeech,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/flashcard-creation/suggest-category');

      print('🏷️ Suggest category for: $term');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'term': term,
          'meaning': meaning,
          'partOfSpeech': partOfSpeech,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CategorySuggestionResult.fromJson(data);
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Category suggestion error: $e');
      rethrow;
    }
  }

  /// ========================================
  /// STEP 3: Create flashcard
  /// ========================================
  static Future<FlashcardCreateResult> create(FlashcardCreateRequest request) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/flashcard-creation/create');

      print('💾 Creating flashcard: ${request.term}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FlashcardCreateResult.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        return FlashcardCreateResult.fromJson(data);
      }
    } catch (e) {
      print('❌ Create error: $e');
      rethrow;
    }
  }

  /// ========================================
  /// BATCH: Tạo nhiều flashcard
  /// ========================================
  static Future<BatchCreateResult> batchCreate(List<FlashcardCreateRequest> requests) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/flashcard-creation/batch');

      print('📚 Batch creating ${requests.length} flashcards');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requests.map((e) => e.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BatchCreateResult.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        return BatchCreateResult.fromJson(data);
      }
    } catch (e) {
      print('❌ Batch create error: $e');
      rethrow;
    }
  }

  /// Preview nhiều từ cùng lúc
  static Future<List<FlashcardPreviewResult>> batchPreview(List<String> terms) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/flashcard-creation/batch-preview');

      print('📝 Batch preview ${terms.length} terms');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'terms': terms}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlashcardPreviewResult.fromJson(e)).toList();
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Batch preview error: $e');
      rethrow;
    }
  }
}

/// ================== DTOs ==================

/// Kết quả preview flashcard
class FlashcardPreviewResult {
  final bool success;
  final String? message;
  final String term;
  final DictionaryLookupResult? dictionaryResult;
  final List<ImageInfo> imageSuggestions;

  FlashcardPreviewResult({
    required this.success,
    this.message,
    required this.term,
    this.dictionaryResult,
    required this.imageSuggestions,
  });

  factory FlashcardPreviewResult.fromJson(Map<String, dynamic> json) {
    return FlashcardPreviewResult(
      success: json['success'] ?? false,
      message: json['message'],
      term: json['term'] ?? '',
      dictionaryResult: json['dictionaryResult'] != null
          ? DictionaryLookupResult.fromJson(json['dictionaryResult'])
          : null,
      imageSuggestions: (json['imageSuggestions'] as List<dynamic>?)
          ?.map((e) => ImageInfo.fromJson(e))
          .toList() ??
          [],
    );
  }

  /// Check if dictionary found the word
  bool get isFoundInDictionary => dictionaryResult?.found ?? false;

  /// Get Vietnamese meaning
  String? get vietnameseMeaning => dictionaryResult?.meanings;

  /// Get English definition
  String? get englishDefinition => dictionaryResult?.definitions;

  /// Get phonetic
  String? get phonetic => dictionaryResult?.phonetic;

  /// Get part of speech
  String? get partOfSpeech => dictionaryResult?.partOfSpeech;
}

/// Request tạo flashcard
class FlashcardCreateRequest {
  final String term;
  final String? partOfSpeech;
  final String? phonetic;
  final String? meaning;          // Vietnamese
  final String? definition;       // English
  final String? example;
  final String? selectedImageUrl;
  final int? categoryId;
  final bool generateAudio;

  FlashcardCreateRequest({
    required this.term,
    this.partOfSpeech,
    this.phonetic,
    this.meaning,
    this.definition,
    this.example,
    this.selectedImageUrl,
    this.categoryId,
    this.generateAudio = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'partOfSpeech': partOfSpeech,
      'phonetic': phonetic,
      'meaning': meaning,
      'definition': definition,
      'example': example,
      'selectedImageUrl': selectedImageUrl,
      'categoryId': categoryId,
      'generateAudio': generateAudio,
    };
  }
}

/// Kết quả tạo flashcard
class FlashcardCreateResult {
  final bool success;
  final String? message;
  final int? flashcardId;

  FlashcardCreateResult({
    required this.success,
    this.message,
    this.flashcardId,
  });

  factory FlashcardCreateResult.fromJson(Map<String, dynamic> json) {
    return FlashcardCreateResult(
      success: json['success'] ?? false,
      message: json['message'],
      flashcardId: json['flashcardId'],
    );
  }
}

/// Kết quả batch create
class BatchCreateResult {
  final bool success;
  final String? message;
  final int totalRequested;
  final int successCount;
  final int failCount;
  final List<FlashcardCreateResult> results;

  BatchCreateResult({
    required this.success,
    this.message,
    required this.totalRequested,
    required this.successCount,
    required this.failCount,
    required this.results,
  });

  factory BatchCreateResult.fromJson(Map<String, dynamic> json) {
    return BatchCreateResult(
      success: json['success'] ?? false,
      message: json['message'],
      totalRequested: json['totalRequested'] ?? 0,
      successCount: json['successCount'] ?? 0,
      failCount: json['failCount'] ?? 0,
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => FlashcardCreateResult.fromJson(e))
          .toList() ??
          [],
    );
  }

  /// Success percentage
  double get successRate => totalRequested > 0 ? successCount / totalRequested : 0;
}