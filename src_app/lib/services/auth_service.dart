import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8080/api/users';

  /// ✅ Login và lưu token + user info
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Login response status: ${response.statusCode}');
      print('📦 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Kiểm tra format response
        if (!data.containsKey('token') || !data.containsKey('user')) {
          throw Exception('Response không đúng format');
        }

        final prefs = await SharedPreferences.getInstance();

        // Lưu token
        await prefs.setString('auth_token', data['token']);

        // Lưu user info
        await prefs.setString('user_info', jsonEncode(data['user']));

        print('✅ Đăng nhập thành công');
        print('👤 User: ${data['user']}');

        return data;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      print('❌ Error in login: $e');
      rethrow;
    }
  }

  /// ✅ Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
    DateTime? dob,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
      };

      if (fullName != null && fullName.isNotEmpty) {
        body['fullName'] = fullName;
      }

      if (dob != null) {
        body['dob'] = dob.toIso8601String().split('T')[0];
      }

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📡 Register response status: ${response.statusCode}');
      print('📦 Register response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data;
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      print('❌ Error in register: $e');
      rethrow;
    }
  }

  /// ✅ Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
    print('✅ Đăng xuất thành công');
  }

  /// ✅ Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  /// ✅ Get current user from SharedPreferences
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_info');

      if (userJson == null) {
        return null;
      }

      final userData = jsonDecode(userJson);
      return UserModel.fromJson(userData);
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  /// ✅ Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// ✅ Update user info in SharedPreferences
  static Future<void> updateUserInfo(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_info', jsonEncode(user.toJson()));
  }
}