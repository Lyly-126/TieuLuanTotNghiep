import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service gợi ý hình ảnh cho flashcard
class ImageSuggestionService {
  /// Lấy danh sách ảnh gợi ý cho từ vựng
  /// [word] - Từ vựng cần tìm ảnh
  /// [count] - Số lượng ảnh (mặc định 5, tối đa 10)
  static Future<ImageSuggestionResult> suggestImages(String word, {int count = 5}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/images/suggest')
          .replace(queryParameters: {
        'word': word,
        'count': count.toString(),
      });

      print('🖼️ Getting $count image suggestions for: $word');

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ImageSuggestionResult.fromJson(data);
      } else {
        throw Exception('Failed to get image suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Image suggestion error: $e');
      rethrow;
    }
  }

  /// Kiểm tra trạng thái service
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/images/status');

      final response = await http.get(uri, headers: {
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get status');
      }
    } catch (e) {
      print('❌ Image service status error: $e');
      rethrow;
    }
  }
}

/// Kết quả gợi ý hình ảnh
class ImageSuggestionResult {
  final bool success;
  final String? message;
  final String? word;
  final int totalFound;
  final List<ImageInfo> images;

  ImageSuggestionResult({
    required this.success,
    this.message,
    this.word,
    required this.totalFound,
    required this.images,
  });

  factory ImageSuggestionResult.fromJson(Map<String, dynamic> json) {
    return ImageSuggestionResult(
      success: json['success'] ?? false,
      message: json['message'],
      word: json['word'],
      totalFound: json['totalFound'] ?? 0,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ImageInfo.fromJson(e))
          .toList() ??
          [],
    );
  }
}

/// Thông tin ảnh
class ImageInfo {
  final int? id;
  final String url;           // URL mặc định (medium)
  final String? original;     // Full resolution
  final String? large;        // 940px wide
  final String? medium;       // 350px wide
  final String? small;        // 130px wide
  final String? tiny;         // 100x100
  final String? photographer;
  final String? photographerUrl;
  final String? alt;

  ImageInfo({
    this.id,
    required this.url,
    this.original,
    this.large,
    this.medium,
    this.small,
    this.tiny,
    this.photographer,
    this.photographerUrl,
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
      tiny: json['tiny'],
      photographer: json['photographer'],
      photographerUrl: json['photographerUrl'],
      alt: json['alt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'original': original,
      'large': large,
      'medium': medium,
      'small': small,
      'tiny': tiny,
      'photographer': photographer,
      'photographerUrl': photographerUrl,
      'alt': alt,
    };
  }
}