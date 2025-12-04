// File: lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_utils.dart';

/// 🌐 API Client - Wrapper cho HTTP requests với authentication
///
/// Class này cung cấp các method để gọi API với:
/// - Tự động thêm token vào header
/// - Xử lý 401 Unauthorized (token hết hạn)
/// - Logging chi tiết cho debugging
/// - Error handling thống nhất
class ApiClient {
  /// 📤 GET request với authentication
  ///
  /// Parameters:
  ///   - url: URI endpoint
  ///   - additionalHeaders: Headers bổ sung (optional)
  ///
  /// Returns: http.Response
  /// Throws: Exception nếu không có token hoặc token hết hạn
  static Future<http.Response> authenticatedGet(
      Uri url, {
        Map<String, String>? additionalHeaders,
      }) async {
    print('═══════════════════════════════════════');
    print('📤 GET REQUEST');
    print('═══════════════════════════════════════');
    print('URL: $url');

    final token = await TokenUtils.getToken();

    if (token == null || token.isEmpty) {
      print('❌ Token not found - User needs to login');
      throw Exception('Token not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      ...?additionalHeaders,
    };

    print('📋 Headers:');
    print('   Authorization: Bearer ${token.substring(0, 20)}...');
    print('   Content-Type: application/json; charset=utf-8');
    if (additionalHeaders != null) {
      additionalHeaders.forEach((key, value) {
        print('   $key: $value');
      });
    }

    try {
      final response = await http.get(url, headers: headers);

      print('───────────────────────────────────────');
      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Length: ${response.body.length} bytes');

      // ✅ XỬ LÝ 401: Token hết hạn
      if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token expired or invalid');
        await TokenUtils.clearToken();
        throw Exception('Session expired. Please login again.');
      }

      // ✅ XỬ LÝ 403: Không có quyền
      if (response.statusCode == 403) {
        print('❌ 403 Forbidden - Insufficient permissions');
        throw Exception('You do not have permission to access this resource.');
      }

      print('═══════════════════════════════════════');

      return response;
    } catch (e) {
      print('❌ Request Error: $e');
      print('═══════════════════════════════════════');
      rethrow;
    }
  }

  /// 📤 POST request với authentication
  ///
  /// Parameters:
  ///   - url: URI endpoint
  ///   - body: Request body (Map hoặc String)
  ///   - additionalHeaders: Headers bổ sung (optional)
  ///
  /// Returns: http.Response
  /// Throws: Exception nếu không có token hoặc token hết hạn
  static Future<http.Response> authenticatedPost(
      Uri url, {
        required dynamic body,
        Map<String, String>? additionalHeaders,
      }) async {
    print('═══════════════════════════════════════');
    print('📤 POST REQUEST');
    print('═══════════════════════════════════════');
    print('URL: $url');

    final token = await TokenUtils.getToken();

    if (token == null || token.isEmpty) {
      print('❌ Token not found - User needs to login');
      throw Exception('Token not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      ...?additionalHeaders,
    };

    print('📋 Headers:');
    print('   Authorization: Bearer ${token.substring(0, 20)}...');
    print('   Content-Type: application/json; charset=utf-8');

    // Convert body to JSON if needed
    final String jsonBody = body is String ? body : json.encode(body);
    print('📦 Request Body: $jsonBody');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonBody,
      );

      print('───────────────────────────────────────');
      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      // ✅ XỬ LÝ 401: Token hết hạn
      if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token expired or invalid');
        await TokenUtils.clearToken();
        throw Exception('Session expired. Please login again.');
      }

      // ✅ XỬ LÝ 403: Không có quyền
      if (response.statusCode == 403) {
        print('❌ 403 Forbidden - Insufficient permissions');
        throw Exception('You do not have permission to perform this action.');
      }

      print('═══════════════════════════════════════');

      return response;
    } catch (e) {
      print('❌ Request Error: $e');
      print('═══════════════════════════════════════');
      rethrow;
    }
  }

  /// 📤 PUT request với authentication
  ///
  /// Parameters:
  ///   - url: URI endpoint
  ///   - body: Request body (Map hoặc String)
  ///   - additionalHeaders: Headers bổ sung (optional)
  ///
  /// Returns: http.Response
  /// Throws: Exception nếu không có token hoặc token hết hạn
  static Future<http.Response> authenticatedPut(
      Uri url, {
        required dynamic body,
        Map<String, String>? additionalHeaders,
      }) async {
    print('═══════════════════════════════════════');
    print('📤 PUT REQUEST');
    print('═══════════════════════════════════════');
    print('URL: $url');

    final token = await TokenUtils.getToken();

    if (token == null || token.isEmpty) {
      print('❌ Token not found - User needs to login');
      throw Exception('Token not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      ...?additionalHeaders,
    };

    final String jsonBody = body is String ? body : json.encode(body);
    print('📦 Request Body: $jsonBody');

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonBody,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token expired or invalid');
        await TokenUtils.clearToken();
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode == 403) {
        print('❌ 403 Forbidden - Insufficient permissions');
        throw Exception('You do not have permission to perform this action.');
      }

      print('═══════════════════════════════════════');

      return response;
    } catch (e) {
      print('❌ Request Error: $e');
      print('═══════════════════════════════════════');
      rethrow;
    }
  }

  /// 📤 DELETE request với authentication
  ///
  /// Parameters:
  ///   - url: URI endpoint
  ///   - additionalHeaders: Headers bổ sung (optional)
  ///
  /// Returns: http.Response
  /// Throws: Exception nếu không có token hoặc token hết hạn
  static Future<http.Response> authenticatedDelete(
      Uri url, {
        Map<String, String>? additionalHeaders,
      }) async {
    print('═══════════════════════════════════════');
    print('📤 DELETE REQUEST');
    print('═══════════════════════════════════════');
    print('URL: $url');

    final token = await TokenUtils.getToken();

    if (token == null || token.isEmpty) {
      print('❌ Token not found - User needs to login');
      throw Exception('Token not found. Please login again.');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      ...?additionalHeaders,
    };

    try {
      final response = await http.delete(url, headers: headers);

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token expired or invalid');
        await TokenUtils.clearToken();
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode == 403) {
        print('❌ 403 Forbidden - Insufficient permissions');
        throw Exception('You do not have permission to perform this action.');
      }

      print('═══════════════════════════════════════');

      return response;
    } catch (e) {
      print('❌ Request Error: $e');
      print('═══════════════════════════════════════');
      rethrow;
    }
  }

  /// 🔄 Retry request with new token (for future refresh token implementation)
  ///
  /// Hiện tại chưa implement refresh token, nhưng method này đã sẵn sàng
  /// cho việc mở rộng trong tương lai
  static Future<http.Response> retryWithNewToken(
      Future<http.Response> Function() request,
      ) async {
    try {
      return await request();
    } on Exception catch (e) {
      if (e.toString().contains('Session expired')) {
        // TODO: Implement refresh token logic here
        // 1. Call refresh token endpoint
        // 2. Save new token
        // 3. Retry original request
        rethrow;
      }
      rethrow;
    }
  }
}