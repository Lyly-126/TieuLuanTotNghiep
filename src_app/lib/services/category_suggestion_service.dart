import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service gợi ý category cho flashcard bằng AI
class CategorySuggestionService {
  /// Gợi ý categories phù hợp cho từ vựng
  /// [word] - Từ vựng
  /// [meaning] - Nghĩa tiếng Việt (optional)
  /// [partOfSpeech] - Loại từ (optional)
  static Future<CategorySuggestionResult> suggestCategories({
    required String word,
    String? meaning,
    String? partOfSpeech,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories/suggest');

      print('🏷️ Suggesting categories for: $word');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
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
        throw Exception('Failed to get category suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Category suggestion error: $e');
      rethrow;
    }
  }

  /// Gợi ý categories qua GET (simple)
  static Future<CategorySuggestionResult> suggestCategoriesSimple(String word) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories/suggest')
          .replace(queryParameters: {'word': word});

      final response = await http.get(uri, headers: {
        'ngrok-skip-browser-warning': 'true',
      });

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