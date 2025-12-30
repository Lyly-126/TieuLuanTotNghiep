// File: lib/services/study_pack_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/study_pack_model.dart';

class StudyPackService {
  // ⚠️ Android Emulator dùng 10.0.2.2
  // static const String baseUrl = 'http://localhost:8080/api/study-packs';
  // iOS Simulator: http://localhost:8080/api/study-packs
  // Prod: https://yourdomain.com/api/study-packs

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ✅ THÊM: Headers chung cho tất cả requests
  static Map<String, String> _getPublicHeaders() {
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // ✅ Bypass ngrok warning
    };
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    if (token == null) throw Exception('Vui lòng đăng nhập lại');

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // ✅ Bypass ngrok warning
    };
  }

  // ==================== PUBLIC ====================

  static Future<List<StudyPackModel>> getAllPacks() async {
    try {
      final uri = Uri.parse(ApiConfig.studyPackBase);
      final response = await http.get(
        uri,
        headers: _getPublicHeaders(), // ✅ SỬA: Dùng headers chung
      );

      print('[StudyPackService] GET $uri');
      print('[StudyPackService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        print('[StudyPackService] ✅ Loaded ${data.length} packs');
        return data.map((e) => StudyPackModel.fromJson(e)).toList();
      } else {
        print('[StudyPackService] ❌ Failed: ${response.body}');
        throw Exception('Không thể tải danh sách gói học tập');
      }
    } catch (e) {
      print('[StudyPackService] ❌ Exception: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  static Future<StudyPackModel> getPackById(int id) async {
    try {
      final uri = Uri.parse(ApiConfig.studyPackDetail(id));
      final response = await http.get(
        uri,
        headers: _getPublicHeaders(), // ✅ SỬA: Dùng headers chung
      );

      if (response.statusCode == 200) {
        return StudyPackModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy gói học tập');
      } else {
        throw Exception('Không thể tải thông tin gói');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  // ==================== ADMIN ====================

  static Future<StudyPackModel> createPack({
    required String name,
    required String description,
    required double price,
    required int durationDays,
    String? targetRole, // ✅ THÊM: Hỗ trợ targetRole
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.studyPackBase}/admin');

      final body = {
        'name': name,
        'description': description,
        'price': price,
        'durationDays': durationDays,
      };

      // ✅ Thêm targetRole nếu có
      if (targetRole != null) {
        body['targetRole'] = targetRole;
      }

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return StudyPackModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo gói học tập');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  static Future<StudyPackModel> updatePack({
    required int id,
    required String name,
    required String description,
    required double price,
    required int durationDays,
    String? targetRole, // ✅ THÊM: Hỗ trợ targetRole
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.studyPackBase}/admin/$id');

      final body = {
        'name': name,
        'description': description,
        'price': price,
        'durationDays': durationDays,
      };

      // ✅ Thêm targetRole nếu có
      if (targetRole != null) {
        body['targetRole'] = targetRole;
      }

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return StudyPackModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể cập nhật gói');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  static Future<void> deletePack(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.studyPackBase}/admin/$id');

      final response = await http.delete(
        uri,
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể xóa gói');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Admin: Lấy tất cả gói (không lọc)
  static Future<List<StudyPackModel>> getAllPacksAdmin() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.studyPackBase}/admin/all');

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => StudyPackModel.fromJson(e)).toList();
      } else {
        throw Exception('Không thể tải danh sách gói học tập');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}