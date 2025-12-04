// File: lib/utils/token_utils.dart
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 Token Utilities - Helper class để quản lý token
///
/// Class này cung cấp các method tiện ích để:
/// - Kiểm tra token có hợp lệ không
/// - Lấy token hiện tại
/// - Debug thông tin token
/// - Xóa token (logout)
class TokenUtils {
  /// ✅ Kiểm tra token có tồn tại và hợp lệ không
  ///
  /// Returns: true nếu token tồn tại và không rỗng
  static Future<bool> hasValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print('🔍 Token Check:');
      print('   Token exists: ${token != null}');
      print('   Token not empty: ${token?.isNotEmpty ?? false}');

      return token != null && token.isNotEmpty;
    } catch (e) {
      print('❌ Error checking token: $e');
      return false;
    }
  }

  /// ✅ Lấy token hiện tại từ SharedPreferences
  ///
  /// Returns: Token string hoặc null nếu không tồn tại
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        print('✅ Token retrieved: ${token.substring(0, min(20, token.length))}...');
      } else {
        print('⚠️ Token not found in SharedPreferences');
      }

      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  /// 🔍 Debug: In toàn bộ thông tin token và user
  ///
  /// Hữu ích khi debug các vấn đề về authentication
  static Future<void> debugTokenInfo() async {
    print('═══════════════════════════════════════');
    print('🔍 TOKEN DEBUG INFO');
    print('═══════════════════════════════════════');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Token info
      final token = prefs.getString('auth_token');
      print('Token Status: ${token != null ? '✅ EXISTS' : '❌ NULL'}');

      if (token != null) {
        print('Token Length: ${token.length}');
        final previewLength = min(40, token.length);
        print('Token Preview: ${token.substring(0, previewLength)}...');

        // Kiểm tra format cơ bản của JWT
        final parts = token.split('.');
        print('Token Parts: ${parts.length} (should be 3 for valid JWT)');
      }

      // User info
      final userId = prefs.getInt('user_id');
      final userEmail = prefs.getString('user_email');
      final userRole = prefs.getString('user_role');
      final userStatus = prefs.getString('user_status');
      final userFullName = prefs.getString('user_fullname');

      print('───────────────────────────────────────');
      print('User ID: $userId');
      print('User Email: $userEmail');
      print('User Role: $userRole');
      print('User Status: $userStatus');
      print('User FullName: $userFullName');

    } catch (e) {
      print('❌ Error in debugTokenInfo: $e');
    }

    print('═══════════════════════════════════════');
  }

  /// ✅ Xóa token và tất cả thông tin user (logout)
  ///
  /// Sử dụng khi user logout hoặc token hết hạn
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Xóa token
      await prefs.remove('auth_token');

      // Xóa user info
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_role');
      await prefs.remove('user_status');
      await prefs.remove('user_fullname');

      print('✅ Token và user info đã được xóa');
    } catch (e) {
      print('❌ Error clearing token: $e');
      rethrow;
    }
  }

  /// 🔄 Verify token sau khi login
  ///
  /// Kiểm tra xem token có được lưu đúng không
  static Future<bool> verifyTokenAfterLogin(String expectedToken) async {
    try {
      final savedToken = await getToken();

      print('✅ Token Verification:');
      print('   Expected length: ${expectedToken.length}');
      print('   Saved length: ${savedToken?.length ?? 0}');
      print('   Tokens match: ${expectedToken == savedToken}');

      return expectedToken == savedToken;
    } catch (e) {
      print('❌ Error verifying token: $e');
      return false;
    }
  }

  /// 📋 Get authentication headers
  ///
  /// Returns: Map với Authorization và Content-Type headers
  /// Throws: Exception nếu token không tồn tại
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token not found. Please login again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  /// 🕐 Check if user is logged in
  ///
  /// Returns: true nếu có cả token và user_id
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.containsKey('auth_token');
      final hasUserId = prefs.containsKey('user_id');

      print('🔍 Login Status:');
      print('   Has Token: $hasToken');
      print('   Has User ID: $hasUserId');
      print('   Is Logged In: ${hasToken && hasUserId}');

      return hasToken && hasUserId;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }
}