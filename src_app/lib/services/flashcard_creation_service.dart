import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
// Import CategorySuggestionResult và CategorySuggestion từ category_suggestion_service
import 'category_suggestion_service.dart';

/// Service tạo Flashcard mới
///
/// Flow:
/// 1. preview() → Tra từ điển + Lấy 5 ảnh
/// 2. suggestCategory() → AI gợi ý category
/// 3. create() → Tạo flashcard (với userId)
class FlashcardCreationService {

  /// Lấy token từ SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// ✅ Headers với authentication token
  static Future<Map<String, String>> _getPublicHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    // static Map<String, String> _getPublicHeaders() {
    //   return {
    //     'Content-Type': 'application/json',
    //     'ngrok-skip-browser-warning': 'true', // ✅ Bypass ngrok warning
    //   };
    // }

    // Luôn gửi token nếu có
    final token = await _getToken();
    print('🔑 Token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('✅ Authorization header added');
    } else {
      print('⚠️ No token found - request will be unauthenticated');
    }

    return headers;
  }

  /// STEP 1: Preview - Tra từ điển + lấy 5 ảnh gợi ý
  static Future<FlashcardPreviewResult> preview(String word) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flashcard-creation/preview';
      print('📝 Preview: POST $url');

      final headers = await _getPublicHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'word': word}),
      );

      print('📥 Response: ${response.statusCode}');

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

  /// STEP 2: Gợi ý category bằng AI
  /// Sử dụng CategorySuggestionResult từ category_suggestion_service.dart
  static Future<CategorySuggestionResult> suggestCategory({
    required String word,
    String? meaning,
    String? partOfSpeech,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flashcard-creation/suggest-category';
      print('🏷️ Suggest category: POST $url');

      final headers = await _getPublicHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'word': word,
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
      print('❌ Suggest category error: $e');
      rethrow;
    }
  }

  /// STEP 3: Tạo flashcard
  static Future<FlashcardCreateResult> create(FlashcardCreateRequest request) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flashcard-creation/create';
      print('💾 Create: POST $url');

      final headers = await _getPublicHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('📥 Create response: ${response.statusCode}');
      final data = jsonDecode(response.body);
      return FlashcardCreateResult.fromJson(data);
    } catch (e) {
      print('❌ Create error: $e');
      rethrow;
    }
  }

  /// BATCH: Tạo nhiều flashcard
  static Future<BatchCreateResult> batchCreate(List<FlashcardCreateRequest> requests) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flashcard-creation/batch';

      final headers = await _getPublicHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requests.map((e) => e.toJson()).toList()),
      );

      final data = jsonDecode(response.body);
      return BatchCreateResult.fromJson(data);
    } catch (e) {
      print('❌ Batch create error: $e');
      rethrow;
    }
  }

  /// BATCH: Preview nhiều từ
  static Future<List<FlashcardPreviewResult>> batchPreview(List<String> words) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flashcard-creation/batch-preview';

      final headers = await _getPublicHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'words': words}),
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

// ================== DTOs ==================

/// Kết quả preview flashcard
class FlashcardPreviewResult {
  final bool success;
  final String? message;
  final String word;
  final DictionaryLookupResult? dictionaryResult;
  final List<ImageInfo> imageSuggestions;

  FlashcardPreviewResult({
    required this.success,
    this.message,
    required this.word,
    this.dictionaryResult,
    required this.imageSuggestions,
  });

  factory FlashcardPreviewResult.fromJson(Map<String, dynamic> json) {
    return FlashcardPreviewResult(
      success: json['success'] ?? false,
      message: json['message'],
      word: json['word'] ?? '',
      dictionaryResult: json['dictionaryResult'] != null
          ? DictionaryLookupResult.fromJson(json['dictionaryResult'])
          : null,
      imageSuggestions: (json['imageSuggestions'] as List<dynamic>?)
          ?.map((e) => ImageInfo.fromJson(e))
          .toList() ?? [],
    );
  }

  // ============ Getters cho backward compatibility ============

  bool get isFoundInDictionary => dictionaryResult?.found ?? false;
  String? get phonetic => dictionaryResult?.phonetic;
  String? get partOfSpeech => dictionaryResult?.partOfSpeech;
  String? get partOfSpeechVi => dictionaryResult?.partOfSpeechVi;

  /// Nghĩa tiếng Việt (alias cho code cũ dùng vietnameseMeaning)
  String? get meaning => dictionaryResult?.meanings;
  String? get vietnameseMeaning => dictionaryResult?.meanings;

  /// Định nghĩa tiếng Anh (alias cho code cũ dùng englishDefinition)
  String? get definition => dictionaryResult?.definitions;
  String? get englishDefinition => dictionaryResult?.definitions;
}

/// Kết quả tra từ điển
class DictionaryLookupResult {
  final bool found;
  final String? word;
  final String? partOfSpeech;
  final String? partOfSpeechVi;
  final String? phonetic;
  final String? definitions;
  final String? meanings;
  final String? source;
  final String? errorMessage;

  DictionaryLookupResult({
    required this.found,
    this.word,
    this.partOfSpeech,
    this.partOfSpeechVi,
    this.phonetic,
    this.definitions,
    this.meanings,
    this.source,
    this.errorMessage,
  });

  factory DictionaryLookupResult.fromJson(Map<String, dynamic> json) {
    return DictionaryLookupResult(
      found: json['found'] ?? false,
      word: json['word'],
      partOfSpeech: json['partOfSpeech'],
      partOfSpeechVi: json['partOfSpeechVi'],
      phonetic: json['phonetic'],
      definitions: json['definitions'],
      meanings: json['meanings'],
      source: json['source'],
      errorMessage: json['errorMessage'],
    );
  }
}

/// Thông tin ảnh từ Pexels
class ImageInfo {
  final int? id;
  final String url;
  final String? original;
  final String? large;
  final String? medium;
  final String? small;
  final String? photographer;
  final String? alt;

  ImageInfo({
    this.id,
    required this.url,
    this.original,
    this.large,
    this.medium,
    this.small,
    this.photographer,
    this.alt,
  });

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      id: json['id'],
      url: json['url'] ?? json['medium'] ?? '',
      original: json['original'],
      large: json['large'],
      medium: json['medium'],
      small: json['small'],
      photographer: json['photographer'],
      alt: json['alt'],
    );
  }
}

/// Request tạo flashcard
class FlashcardCreateRequest {
  final String word;
  final String? partOfSpeech;
  final String? partOfSpeechVi;
  final String? phonetic;
  final String meaning;           // Vietnamese (bắt buộc)
  final String? definition;       // English
  final String? example;
  final String? selectedImageUrl;
  final int? categoryId;
  final bool generateAudio;

  FlashcardCreateRequest({
    required this.word,
    this.partOfSpeech,
    this.partOfSpeechVi,
    this.phonetic,
    required this.meaning,
    this.definition,
    this.example,
    this.selectedImageUrl,
    this.categoryId,
    this.generateAudio = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'partOfSpeech': partOfSpeech,
      'partOfSpeechVi': partOfSpeechVi,
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
  final FlashcardDTO? flashcard;

  FlashcardCreateResult({
    required this.success,
    this.message,
    this.flashcardId,
    this.flashcard,
  });

  factory FlashcardCreateResult.fromJson(Map<String, dynamic> json) {
    return FlashcardCreateResult(
      success: json['success'] ?? false,
      message: json['message'],
      flashcardId: json['flashcardId'],
      flashcard: json['flashcard'] != null
          ? FlashcardDTO.fromJson(json['flashcard'])
          : null,
    );
  }
}

/// Flashcard DTO từ response
class FlashcardDTO {
  final int id;
  final int? userId;
  final String word;
  final String? partOfSpeech;
  final String? partOfSpeechVi;
  final String? phonetic;
  final String meaning;
  final String? imageUrl;
  final String? ttsUrl;
  final int? categoryId;

  FlashcardDTO({
    required this.id,
    this.userId,
    required this.word,
    this.partOfSpeech,
    this.partOfSpeechVi,
    this.phonetic,
    required this.meaning,
    this.imageUrl,
    this.ttsUrl,
    this.categoryId,
  });

  factory FlashcardDTO.fromJson(Map<String, dynamic> json) {
    return FlashcardDTO(
      id: json['id'] ?? 0,
      userId: json['userId'],
      word: json['word'] ?? '',
      partOfSpeech: json['partOfSpeech'],
      partOfSpeechVi: json['partOfSpeechVi'],
      phonetic: json['phonetic'],
      meaning: json['meaning'] ?? '',
      imageUrl: json['imageUrl'],
      ttsUrl: json['ttsUrl'],
      categoryId: json['categoryId'],
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
          .toList() ?? [],
    );
  }

  double get successRate => totalRequested > 0 ? successCount / totalRequested : 0;
}