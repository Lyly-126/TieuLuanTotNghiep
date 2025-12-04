import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart'; // ✅ FIXED: Import AppConstants
import '../models/category_model.dart';

class CategoryService {
  // ✅ FIXED: Sử dụng AppConstants thay vì hardcode localhost
  static const String baseUrl = '${AppConstants.baseUrl}/api/categories';

  // ==================== LOGGING & HELPERS ====================

  static void _log(String message) {
    print('[CategoryService] $message');
  }

  /// Lấy token từ SharedPreferences
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    return token;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  // ==================== CATEGORY CRUD ====================

  /// ✅ Lấy categories available cho user (system + owned)
  static Future<List<CategoryModel>> getMyCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/my');

      _log('GET My Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải categories');
      }
    } catch (e) {
      _log('❌ Error in getMyCategories: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ Lấy system categories (public)
  static Future<List<CategoryModel>> getSystemCategories() async {
    try {
      final uri = Uri.parse('$baseUrl/system');

      _log('GET System Categories URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải system categories');
      }
    } catch (e) {
      _log('❌ Error in getSystemCategories: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ Tạo category cá nhân
  static Future<CategoryModel> createUserCategory(String name) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/create');

      _log('POST Create User Category URL: $uri');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'name': name}),
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo category');
      }
    } catch (e) {
      _log('❌ Error in createUserCategory: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ TEACHER: Tạo category cho lớp học
  static Future<CategoryModel> createClassCategory({
    required String name,
    required int classId,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/class');

      _log('POST Create Class Category URL: $uri');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'classId': classId,
        }),
      );

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CategoryModel.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo category');
      }
    } catch (e) {
      _log('❌ Error in createClassCategory: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ Lấy categories của lớp học
  static Future<List<CategoryModel>> getCategoriesForClass(int classId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/class/$classId');

      _log('GET Categories for Class URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải categories của lớp');
      }
    } catch (e) {
      _log('❌ Error in getCategoriesForClass: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ TEACHER: Lấy tất cả categories của teacher
  static Future<List<CategoryModel>> getTeacherCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/teacher');

      _log('GET Teacher Categories URL: $uri');

      final response = await http.get(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải categories của teacher');
      }
    } catch (e) {
      _log('❌ Error in getTeacherCategories: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ Xóa category
  static Future<void> deleteCategory(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/$categoryId');

      _log('DELETE Category URL: $uri');

      final response = await http.delete(uri, headers: headers);

      _log('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể xóa category');
      }
    } catch (e) {
      _log('❌ Error in deleteCategory: $e');
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ GET categories by class ID
  static Future<List<CategoryModel>> getCategoriesByClassId(int classId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/class/$classId');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách chủ đề');
    }
  }

  /// ✅ CREATE category
  static Future<CategoryModel> createCategory({
    required String name,
    required int classId,
    String? description,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/create');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'name': name,
        'class_id': classId,
        'description': description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return CategoryModel.fromJson(data);
    } else {
      throw Exception('Không thể tạo chủ đề');
    }
  }

  /// ✅ UPDATE category
  static Future<CategoryModel> updateCategory({
    required int categoryId,
    required String name,
    String? description,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/$categoryId');

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return CategoryModel.fromJson(data);
    } else {
      throw Exception('Không thể cập nhật chủ đề');
    }
  }
}