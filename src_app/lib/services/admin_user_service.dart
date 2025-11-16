// File: lib/services/admin_user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminUserService {
  // ✅ Đổi URL phù hợp với môi trường
  static const String baseUrl = 'http://localhost:8080/api/users';

  // Android Emulator: 'http://10.0.2.2:8080/api/users'
  // Thiết bị thật: 'http://YOUR_IP:8080/api/users'

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
      final uri = Uri.parse('$baseUrl/admin/all');

      print('🔍 Calling: $uri');
      print('🔑 Token: ${token.substring(0, 20)}...');

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
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Bạn không có quyền truy cập. Status: ${response.statusCode}');
      } else {
        throw Exception('Không thể tải danh sách người dùng. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in getAllUsers: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Admin: Tìm kiếm users
  static Future<List<Map<String, dynamic>>> searchUsers(String keyword) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/search?keyword=$keyword');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Không thể tìm kiếm người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Admin: Lấy chi tiết user
  static Future<Map<String, dynamic>> getUserDetail(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy người dùng');
      } else {
        throw Exception('Không thể tải thông tin người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ================== KHÓA/MỞ KHÓA ==================

  /// Admin: Khóa tài khoản (dùng isBlocked)
  static Future<Map<String, dynamic>> blockUser(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId/block');

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

  /// Admin: Mở khóa tài khoản
  static Future<Map<String, dynamic>> unblockUser(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId/unblock');

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

  /// Admin: Cấp gói Premium
  static Future<Map<String, dynamic>> grantPremium(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId/grant-premium');

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

  /// Admin: Thu hồi quyền Premium
  static Future<Map<String, dynamic>> revokePremium(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId/revoke-premium');

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

  // ================== KHÁC ==================

  /// Admin: Xóa user (NGUY HIỂM)
  static Future<void> deleteUser(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể xóa người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Admin: Thăng cấp lên Admin
  static Future<Map<String, dynamic>> promoteToAdmin(int userId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId/promote');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Không thể thăng cấp người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  /// Admin: Đổi status
  static Future<Map<String, dynamic>> changeUserStatus({
    required int userId,
    required String status,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('$baseUrl/admin/$userId/status?status=$status');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Không thể thay đổi trạng thái');
      }
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }
}