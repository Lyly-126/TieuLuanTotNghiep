import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';

class CategoryService {
  static const String baseUrl = 'http://localhost:8080/api/categories';

  /// Lấy token từ SharedPreferences
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    return token;
  }

  /// Lấy categories available cho user (system + owned)
  static Future<List<CategoryModel>> getMyCategories() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/my');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải categories');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Lấy system categories (public)
  static Future<List<CategoryModel>> getSystemCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/system');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải system categories');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Tạo category cá nhân
  static Future<CategoryModel> createUserCategory(String name) async {
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
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo category');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// TEACHER: Tạo category cho lớp học
  static Future<CategoryModel> createClassCategory({
    required String name,
    required int classId,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/class');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'classId': classId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo category');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Lấy categories của lớp học
  static Future<List<CategoryModel>> getCategoriesForClass(int classId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/class/$classId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải categories của lớp');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// TEACHER: Lấy tất cả categories của teacher
  static Future<List<CategoryModel>> getTeacherCategories() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/teacher');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải categories của teacher');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Xóa category
  static Future<void> deleteCategory(int categoryId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/$categoryId');

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
        throw Exception(error['message'] ?? 'Không thể xóa category');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Cập nhật category
  static Future<CategoryModel> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/$categoryId');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể cập nhật category');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}