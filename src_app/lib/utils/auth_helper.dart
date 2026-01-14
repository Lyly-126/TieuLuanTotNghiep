import 'package:shared_preferences/shared_preferences.dart';

/// ✅ AUTH HELPER
/// Utility class để quản lý persistent login state
class AuthHelper {
  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _loginTimeKey = 'login_time';

  /// ✅ Lưu thông tin đăng nhập với timestamp
  static Future<void> saveLoginInfo({
    required String token,
    required int userId,
    required String email,
    required String role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setString(_tokenKey, token),
        prefs.setInt(_userIdKey, userId),
        prefs.setString(_userEmailKey, email),
        prefs.setString(_userRoleKey, role),
        prefs.setString(_loginTimeKey, DateTime.now().toIso8601String()),
      ]);

      print('✅ [AuthHelper] Login info saved successfully');
    } catch (e) {
      print('❌ [AuthHelper] Error saving login info: $e');
      rethrow;
    }
  }

  /// ✅ Kiểm tra token có hợp lệ không (dựa trên thời gian)
  static Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if token exists
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) {
        print('⚠️ [AuthHelper] No token found');
        return false;
      }

      // Check login time (Optional: implement token expiry logic)
      final loginTimeStr = prefs.getString(_loginTimeKey);
      if (loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        final now = DateTime.now();
        final daysSinceLogin = now.difference(loginTime).inDays;

        // Token expires after 30 days (adjust as needed)
        if (daysSinceLogin > 30) {
          print('⚠️ [AuthHelper] Token expired (${daysSinceLogin} days old)');
          await clearLoginInfo();
          return false;
        }

        print('✅ [AuthHelper] Token valid (${daysSinceLogin} days old)');
      }

      return true;
    } catch (e) {
      print('❌ [AuthHelper] Error checking token validity: $e');
      return false;
    }
  }

  /// ✅ Lấy token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('❌ [AuthHelper] Error getting token: $e');
      return null;
    }
  }

  /// ✅ Lấy user ID
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      print('❌ [AuthHelper] Error getting user ID: $e');
      return null;
    }
  }

  /// ✅ Lấy user role
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRoleKey);
    } catch (e) {
      print('❌ [AuthHelper] Error getting user role: $e');
      return null;
    }
  }

  /// ✅ Xóa tất cả thông tin đăng nhập
  static Future<void> clearLoginInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_userIdKey),
        prefs.remove(_userEmailKey),
        prefs.remove(_userRoleKey),
        prefs.remove(_loginTimeKey),
      ]);

      print('✅ [AuthHelper] Login info cleared');
    } catch (e) {
      print('❌ [AuthHelper] Error clearing login info: $e');
    }
  }

  /// ✅ Update login timestamp (gọi khi user active)
  static Future<void> updateLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loginTimeKey, DateTime.now().toIso8601String());
      print('✅ [AuthHelper] Login time updated');
    } catch (e) {
      print('❌ [AuthHelper] Error updating login time: $e');
    }
  }

  /// ✅ Debug: Print all auth info
  static Future<void> printAuthInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('=== AUTH INFO ===');
      print('Token: ${prefs.getString(_tokenKey)?.substring(0, 20)}...');
      print('User ID: ${prefs.getInt(_userIdKey)}');
      print('Email: ${prefs.getString(_userEmailKey)}');
      print('Role: ${prefs.getString(_userRoleKey)}');
      print('Login Time: ${prefs.getString(_loginTimeKey)}');
      print('================');
    } catch (e) {
      print('❌ [AuthHelper] Error printing auth info: $e');
    }
  }
}