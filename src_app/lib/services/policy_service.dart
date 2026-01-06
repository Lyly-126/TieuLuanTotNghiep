// File: lib/services/policy_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class PolicyService {
  // ================== COMMON HEADERS ==================

  /// Headers chung cho tất cả requests (bypass ngrok warning)
  static Map<String, String> get _commonHeaders => {
    'ngrok-skip-browser-warning': 'true',
  };

  /// Headers cho requests cần auth
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }

    return {
      ..._commonHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  /// Headers cho requests có body JSON
  static Future<Map<String, String>> _getAuthJsonHeaders() async {
    final headers = await _getAuthHeaders();
    return {
      ...headers,
      'Content-Type': 'application/json',
    };
  }

  // ================== USER METHODS ==================

  /// Lấy tất cả policies ACTIVE (không cần token)
  static Future<List<Map<String, dynamic>>> getActivePolicies() async {
    try {
      final uri = Uri.parse(ApiConfig.policyBase);
      final response = await http.get(
        uri,
        headers: _commonHeaders, // ✅ Thêm header bypass ngrok
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Không thể tải danh sách điều khoản');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy một policy theo ID (không cần token)
  static Future<Map<String, dynamic>> getActivePolicyById(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.policyBase}/$id');
      final response = await http.get(
        uri,
        headers: _commonHeaders, // ✅ Thêm header bypass ngrok
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy điều khoản');
      } else {
        throw Exception('Không thể tải điều khoản');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // ================== ADMIN METHODS ==================

  /// Admin: Lấy tất cả policies (cần token)
  static Future<List<Map<String, dynamic>>> getAllPolicies() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.policyBase}/admin/all');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Bạn không có quyền truy cập');
      } else {
        throw Exception('Không thể tải danh sách điều khoản');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Admin: Lấy một policy theo ID (cần token)
  static Future<Map<String, dynamic>> getPolicyById(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.policyBase}/admin/$id');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy điều khoản');
      } else {
        throw Exception('Không thể tải điều khoản');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Admin: Tạo policy mới
  static Future<Map<String, dynamic>> createPolicy({
    required String title,
    required String body,
    String status = 'ACTIVE',
  }) async {
    try {
      final headers = await _getAuthJsonHeaders();
      final uri = Uri.parse('${ApiConfig.policyBase}/admin');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'title': title,
          'body': body,
          'status': status,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể tạo điều khoản');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Admin: Cập nhật policy
  static Future<Map<String, dynamic>> updatePolicy({
    required int id,
    String? title,
    String? body,
    String? status,
  }) async {
    try {
      final headers = await _getAuthJsonHeaders();
      final uri = Uri.parse('${ApiConfig.policyBase}/admin/$id');

      // Chỉ gửi các field không null
      final Map<String, dynamic> requestBody = {};
      if (title != null) requestBody['title'] = title;
      if (body != null) requestBody['body'] = body;
      if (status != null) requestBody['status'] = status;

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể cập nhật điều khoản');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Admin: Xóa policy
  static Future<void> deletePolicy(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.policyBase}/admin/$id');
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode != 200) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể xóa điều khoản');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Admin: Thay đổi status
  static Future<Map<String, dynamic>> changeStatus({
    required int id,
    required String status,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${ApiConfig.policyBase}/admin/$id/status?status=$status');
      final response = await http.patch(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? 'Không thể thay đổi trạng thái');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}