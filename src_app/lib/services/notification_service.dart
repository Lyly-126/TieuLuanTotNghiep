import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class NotificationService {
  static const String _fcmTokenKey = 'fcm_token';

  /// Lưu FCM token vào server
  static Future<void> saveFcmToken(String token) async {
    try {
      // Lưu local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);

      // Gửi lên server (nếu đã login)
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminders/fcm-token'),
        body: {'fcmToken': token},
      );

      if (response.statusCode == 200) {
        print('✅ FCM token saved to server');
      }
    } catch (e) {
      print('❌ Save FCM token error: $e');
    }
  }

  /// Lấy FCM token từ local
  static Future<String?> getFcmToken() async {
    try {
      // Thử lấy từ Firebase trước
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) return token;

      // Fallback: lấy từ local
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      print('❌ Get FCM token error: $e');
      return null;
    }
  }

  /// Xóa FCM token (khi logout)
  static Future<void> clearFcmToken() async {
    try {
      // Xóa trên server
      await ApiClient.authenticatedDelete(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminders/fcm-token'),
      );

      // Xóa local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);

      print('✅ FCM token cleared');
    } catch (e) {
      print('❌ Clear FCM token error: $e');
    }
  }

  /// Test notification
  static Future<bool> sendTestNotification() async {
    try {
      final token = await getFcmToken();
      if (token == null) return false;

      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminders/test-notification'),
        body: {'fcmToken': token},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test notification error: $e');
      return false;
    }
  }
}