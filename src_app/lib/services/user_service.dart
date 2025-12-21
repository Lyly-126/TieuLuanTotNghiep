import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';  // ← THÊM DÒNG NÀY

class UserService {
  // static const String baseUrl = 'http://localhost:8080/api/users';  // ← ĐÃ COMMENT

  /// ✅ Lấy thông tin user hiện tại từ SharedPreferences
  /// Đọc từ các field riêng lẻ: user_id, user_email, user_role...
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Đọc từng field riêng lẻ (theo cách login_screen.dart đang lưu)
      final userId = prefs.getInt('user_id');
      final userEmail = prefs.getString('user_email');
      final userRole = prefs.getString('user_role');
      final userStatus = prefs.getString('user_status');
      final userFullName = prefs.getString('user_fullname');

      print('📦 Reading from SharedPreferences:');
      print('   user_id: $userId');
      print('   user_email: $userEmail');
      print('   user_role: $userRole');
      print('   user_status: $userStatus');
      print('   user_fullname: $userFullName');

      // Nếu không có user_id hoặc email thì chưa login
      if (userId == null || userEmail == null) {
        print('⚠️ Chưa có thông tin user trong SharedPreferences');
        return null;
      }

      // Tạo UserModel từ các field riêng lẻ
      final userMap = {
        'id': userId,
        'email': userEmail,
        'role': userRole ?? 'NORMAL_USER',
        'status': userStatus ?? 'VERIFIED',
        'fullName': userFullName ?? userEmail.split('@')[0],
        'isBlocked': false,
      };

      print('✅ Constructed user data: $userMap');

      return UserModel.fromJson(userMap);
    } catch (e) {
      print('❌ Error in getCurrentUser: $e');
      return null;
    }
  }

  /// ✅ Logout - xóa tất cả thông tin user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove('user_status');
    await prefs.remove('user_fullname');
    print('✅ Đã logout và xóa tất cả thông tin user');
  }

  /// ✅ Kiểm tra đã login chưa
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token') && prefs.containsKey('user_id');
  }

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

      final uri = Uri.parse('${ApiConfig.userBase}/admin/all');

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