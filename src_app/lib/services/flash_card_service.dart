import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/flashcard_model.dart';

class FlashcardService {
  /// Lấy token từ SharedPreferences (nếu cần authentication)
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// ✅ Headers chung cho tất cả requests
  /// Luôn gửi token nếu có (để tránh 403 với một số endpoint)
  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    // ✅ Luôn gửi token nếu có, không chỉ khi requireAuth
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Lấy tất cả flashcards
  static Future<List<FlashcardModel>> getAllFlashcards() async {
    try {
      final uri = Uri.parse(ApiConfig.flashcardBase);
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

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
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

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
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

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
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

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
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

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
    String? partOfSpeechVi,
    String? phonetic,
    String? imageUrl,
    required String meaning,
    int? categoryId,
    String? ttsUrl,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Vui lòng đăng nhập lại');

      final uri = Uri.parse(ApiConfig.flashcardBase);

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'word': term,  // ✅ Backend dùng 'word' thay vì 'term'
          'partOfSpeech': partOfSpeech,
          'partOfSpeechVi': partOfSpeechVi,
          'phonetic': phonetic,
          'imageUrl': imageUrl,
          'meaning': meaning,
          'categoryId': categoryId,
          'ttsUrl': ttsUrl,
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

  /// ✅ Cập nhật flashcard - chấp nhận int? để tương thích với FlashcardModel.id
  static Future<FlashcardModel> updateFlashcard(
      int? id, {  // ✅ Đổi từ int sang int?
        String? word,  // ✅ Đổi từ term sang word
        String? partOfSpeech,
        String? partOfSpeechVi,
        String? phonetic,
        String? imageUrl,
        String? meaning,
        int? categoryId,
        String? ttsUrl,
      }) async {
    // ✅ Validate id không null
    if (id == null) {
      throw Exception('ID flashcard không hợp lệ');
    }

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Vui lòng đăng nhập lại');

      final uri = Uri.parse('${ApiConfig.flashcardBase}/$id');

      final body = <String, dynamic>{};
      if (word != null) body['word'] = word;  // ✅ Dùng word
      if (partOfSpeech != null) body['partOfSpeech'] = partOfSpeech;
      if (partOfSpeechVi != null) body['partOfSpeechVi'] = partOfSpeechVi;
      if (phonetic != null) body['phonetic'] = phonetic;
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (meaning != null) body['meaning'] = meaning;
      if (categoryId != null) body['categoryId'] = categoryId;
      if (ttsUrl != null) body['ttsUrl'] = ttsUrl;

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(body),
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

  /// ✅ Xóa flashcard - chấp nhận int? để tương thích với FlashcardModel.id
  static Future<bool> deleteFlashcard(int? id) async {  // ✅ Đổi từ int sang int?
    // ✅ Validate id không null
    if (id == null) {
      throw Exception('ID flashcard không hợp lệ');
    }

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Vui lòng đăng nhập lại');

      final uri = Uri.parse('${ApiConfig.flashcardBase}/admin/$id');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}