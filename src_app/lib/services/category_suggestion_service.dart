import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service gợi ý category cho flashcard bằng AI
///
/// ✅ UPDATED: Thêm Authorization header để backend biết user là ai
/// → Chỉ gợi ý categories của user (không lấy system)
class CategorySuggestionService {

  /// Lấy token từ SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Headers với authentication
  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Gợi ý categories phù hợp cho từ vựng
  /// [word] - Từ vựng
  /// [meaning] - Nghĩa tiếng Việt (optional)
  /// [partOfSpeech] - Loại từ (optional)
  ///
  /// ✅ Yêu cầu đăng nhập để lấy đúng categories của user
  static Future<CategorySuggestionResult> suggestCategories({
    required String word,
    String? meaning,
    String? partOfSpeech,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories/suggest');

      // ✅ FIX: Thêm Authorization header
      final headers = await _getHeaders();

      print('🏷️ Suggesting categories for: $word');
      print('🔑 Has token: ${headers.containsKey('Authorization')}');

      final response = await http.post(
        uri,
        headers: headers,  // ✅ Sử dụng headers có token
        body: jsonEncode({
          'word': word,
          'meaning': meaning,
          'partOfSpeech': partOfSpeech,
        }),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CategorySuggestionResult.fromJson(data);
      } else if (response.statusCode == 401) {
        // Unauthorized - user chưa đăng nhập
        return CategorySuggestionResult(
          success: false,
          message: 'Vui lòng đăng nhập để sử dụng tính năng này',
          totalCategories: 0,
          suggestions: [],
        );
      } else {
        final errorBody = response.body;
        print('❌ Error response: $errorBody');
        throw Exception('Failed to get category suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Category suggestion error: $e');
      rethrow;
    }
  }

  /// Gợi ý categories qua GET (simple)
  /// ✅ UPDATED: Thêm Authorization header
  static Future<CategorySuggestionResult> suggestCategoriesSimple(String word) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories/suggest')
          .replace(queryParameters: {'word': word});

      // ✅ FIX: Thêm Authorization header
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CategorySuggestionResult.fromJson(data);
      } else if (response.statusCode == 401) {
        return CategorySuggestionResult(
          success: false,
          message: 'Vui lòng đăng nhập để sử dụng tính năng này',
          totalCategories: 0,
          suggestions: [],
        );
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Category suggestion error: $e');
      rethrow;
    }
  }
}

/// Kết quả gợi ý category
class CategorySuggestionResult {
  final bool success;
  final String? message;
  final String? word;
  final int totalCategories;
  final List<CategorySuggestion> suggestions;

  CategorySuggestionResult({
    required this.success,
    this.message,
    this.word,
    required this.totalCategories,
    required this.suggestions,
  });

  factory CategorySuggestionResult.fromJson(Map<String, dynamic> json) {
    return CategorySuggestionResult(
      success: json['success'] ?? false,
      message: json['message'],
      word: json['word'],
      totalCategories: json['totalCategories'] ?? 0,
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((e) => CategorySuggestion.fromJson(e))
          .toList() ??
          [],
    );
  }
}

/// Category được gợi ý
class CategorySuggestion {
  final int categoryId;
  final String categoryName;
  final String? description;
  final double confidenceScore;  // 0.0 - 1.0
  final String? reason;          // Lý do AI gợi ý

  CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    this.description,
    required this.confidenceScore,
    this.reason,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    return CategorySuggestion(
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      description: json['description'],
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      reason: json['reason'],
    );
  }

  /// Confidence level text
  String get confidenceLevel {
    if (confidenceScore >= 0.8) return 'Rất phù hợp';
    if (confidenceScore >= 0.6) return 'Phù hợp';
    if (confidenceScore >= 0.4) return 'Có thể phù hợp';
    return 'Ít phù hợp';
  }

  /// Confidence percentage
  int get confidencePercent => (confidenceScore * 100).round();
}