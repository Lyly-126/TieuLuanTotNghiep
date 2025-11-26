import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_model.dart';

class ClassService {
  static const String baseUrl = 'http://localhost:8080/api/classes';
  // Android Emulator: 'http://10.0.2.2:8080/api/classes'

  /// Lấy token từ SharedPreferences
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    return token;
  }

  /// Tạo lớp học mới (TEACHER only)
  static Future<ClassModel> createClass({
    required String name,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/create');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ClassModel.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('Chỉ giáo viên mới có thể tạo lớp học');
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo lớp học');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Lấy danh sách lớp của teacher
  static Future<List<ClassModel>> getMyClasses() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/my-classes');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ClassModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách lớp học');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Lấy chi tiết lớp học
  static Future<ClassModel> getClassById(int classId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/$classId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ClassModel.fromJson(data);
      } else {
        throw Exception('Không tìm thấy lớp học');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Cập nhật lớp học
  static Future<ClassModel> updateClass({
    required int classId,
    required String name,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/$classId');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ClassModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể cập nhật lớp học');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Xóa lớp học
  static Future<void> deleteClass(int classId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/$classId');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể xóa lớp học');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Search lớp học
  static Future<List<ClassModel>> searchClasses(String keyword) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/search?keyword=$keyword');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ClassModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tìm kiếm lớp học');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Lấy số lượng categories trong lớp
  static Future<int> getCategoryCount(int classId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/$classId/category-count');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }
}