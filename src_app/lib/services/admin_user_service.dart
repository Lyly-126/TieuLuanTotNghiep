// File: lib/services/admin_user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AdminUserService {
  // static const String baseUrl = 'http://localhost:8080/api/users';

  /// Lấy token từ SharedPreferences
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }
    return token;
  }

  // ================== ADMIN METHODS ==================

  /// Admin: Lấy tất cả users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.adminUsers}/all');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true', // ✅ Bypass ngrok warning
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Bạn không có quyền truy cập');
      } else {
        throw Exception('Không thể tải danh sách người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ================== KHÓA/MỞ KHÓA ==================

  /// ✅ Admin: Khóa tài khoản - CHỈ CẦN 1 THAM SỐ
  static Future<Map<String, dynamic>> blockUser(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.adminUsers}/$userId/block');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể khóa tài khoản');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ Admin: Mở khóa tài khoản - CHỈ CẦN 1 THAM SỐ
  static Future<Map<String, dynamic>> unblockUser(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.adminUsers}/$userId/unblock');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể mở khóa tài khoản');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  // ================== PREMIUM ==================

  /// ✅ Admin: Cấp gói Premium - CHỈ CẦN 1 THAM SỐ
  static Future<Map<String, dynamic>> grantPremium(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.adminUsers}/$userId/grant-premium');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể cấp Premium');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// ✅ Admin: Thu hồi quyền Premium - CHỈ CẦN 1 THAM SỐ
  static Future<Map<String, dynamic>> revokePremium(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.adminUsers}/$userId/revoke-premium');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể thu hồi Premium');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}