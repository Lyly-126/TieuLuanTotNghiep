import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static const String baseUrl = 'http://localhost:8080/api/users';

  /// Lấy token từ SharedPreferences
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    return token;
  }

  Future<List<UserModel>> fetchUsers() async {
    try {
      final token = await _getToken();

      // ✅ SỬA ENDPOINT: Thêm /admin/all
      final uri = Uri.parse('$baseUrl/admin/all');

      // ✅ THÊM AUTHORIZATION HEADER
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => UserModel.fromJson(e)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Bạn không có quyền truy cập');
      } else {
        throw Exception('Không thể tải danh sách người dùng. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in fetchUsers: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }
}