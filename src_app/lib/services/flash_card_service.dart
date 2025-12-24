import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/flashcard_model.dart';

class FlashcardService {
  // Cấu hình base URL
  // static const String baseUrl = 'http://localhost:8080/api/flashcards';
  // Android Emulator: 'http://10.0.2.2:8080/api/flashcards'
  // iOS Simulator: 'http://localhost:8080/api/flashcards'

  /// Lấy token từ SharedPreferences (nếu cần authentication)
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Lấy tất cả flashcards
  static Future<List<FlashcardModel>> getAllFlashcards() async {
    try {
      final uri = Uri.parse(ApiConfig.flashcardBase);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => FlashcardModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách flashcards');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy flashcards theo category
  static Future<List<FlashcardModel>> getFlashcardsByCategory(int categoryId) async {
    try {
      final uri = Uri.parse(ApiConfig.flashcardByCategory(categoryId));

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => FlashcardModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải flashcards theo category');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy một flashcard theo ID
  static Future<FlashcardModel> getFlashcardById(int id) async {
    try {
      final uri = Uri.parse(ApiConfig.flashcardDetail(id));

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return FlashcardModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy flashcard');
      } else {
        throw Exception('Không thể tải flashcard');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Lấy flashcards ngẫu nhiên (dùng cho ôn tập)
  static Future<List<FlashcardModel>> getRandomFlashcards({int limit = 20}) async {
    try {
      final uri = Uri.parse('${ApiConfig.flashcardRandom}?limit=$limit');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => FlashcardModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải flashcards ngẫu nhiên');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Search flashcards theo từ khóa
  static Future<List<FlashcardModel>> searchFlashcards(String keyword) async {
    try {
      final uri = Uri.parse('${ApiConfig.flashcardSearch}?q=${Uri.encodeComponent(keyword)}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => FlashcardModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tìm kiếm flashcards');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// === ADMIN FUNCTIONS (cần authentication) ===

  /// Tạo flashcard mới
  static Future<FlashcardModel> createFlashcard({
    required String term,
    String? partOfSpeech,
    String? phonetic,
    String? imageUrl,
    required String meaning,
    int? categoryId,
    String? ttsUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Vui lòng đăng nhập lại');

      final uri = Uri.parse('${ApiConfig.flashcardBase}/admin');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'term': term,
          'part_of_speech': partOfSpeech,
          'phonetic': phonetic,
          'image_url': imageUrl,
          'meaning': meaning,
          'category_id': categoryId,
          'tts_url': ttsUrl,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return FlashcardModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo flashcard');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Cập nhật flashcard
  static Future<FlashcardModel> updateFlashcard(int id, {
    String? term,
    String? partOfSpeech,
    String? phonetic,
    String? imageUrl,
    String? meaning,
    int? categoryId,
    String? ttsUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Vui lòng đăng nhập lại');

      final uri = Uri.parse('${ApiConfig.flashcardBase}/admin/$id');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (term != null) 'term': term,
          if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
          if (phonetic != null) 'phonetic': phonetic,
          if (imageUrl != null) 'image_url': imageUrl,
          if (meaning != null) 'meaning': meaning,
          if (categoryId != null) 'category_id': categoryId,
          if (ttsUrl != null) 'tts_url': ttsUrl,
        }),
      );

      if (response.statusCode == 200) {
        return FlashcardModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể cập nhật flashcard');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Xóa flashcard
  static Future<bool> deleteFlashcard(int id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Vui lòng đăng nhập lại');

      final uri = Uri.parse('${ApiConfig.flashcardBase}/admin/$id');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // ✅ Bypass ngrok warning
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

}