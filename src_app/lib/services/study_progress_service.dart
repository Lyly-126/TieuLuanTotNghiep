import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/token_utils.dart';
import 'api_client.dart';
import '../models/study_progress_model.dart';

/// Service quản lý Study Progress, Streak, và Reminder
class StudyProgressService {
  // ==================== PROGRESS APIs ====================

  /// Lấy tiến trình học của category
  static Future<CategoryProgressModel> getCategoryProgress(int categoryId) async {
    try {
      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/study/progress/$categoryId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CategoryProgressModel.fromJson(data);
      } else {
        debugPrint('❌ [StudyProgress] Error: ${response.body}');
        // Trả về model rỗng nếu lỗi
        return CategoryProgressModel.empty(categoryId);
      }
    } catch (e) {
      debugPrint('❌ [StudyProgress] getCategoryProgress error: $e');
      return CategoryProgressModel.empty(categoryId);
    }
  }

  /// Cập nhật tiến trình sau khi trả lời câu hỏi
  static Future<Map<String, dynamic>?> updateProgress({
    required int flashcardId,
    required int categoryId,
    required bool isCorrect,
  }) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/study/progress/update'),
        body: {
          'flashcardId': flashcardId,
          'categoryId': categoryId,
          'isCorrect': isCorrect,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ [StudyProgress] updateProgress error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [StudyProgress] updateProgress error: $e');
      return null;
    }
  }

  /// Reset tiến trình học của category
  static Future<bool> resetCategoryProgress(int categoryId) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/study/progress/reset/$categoryId'),
        body: {},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [StudyProgress] resetCategoryProgress error: $e');
      return false;
    }
  }

  /// Lấy các thẻ cần ôn tập
  static Future<List<dynamic>> getCardsToReview({int? categoryId}) async {
    try {
      String url = '${ApiConfig.baseUrl}/api/study/review';
      if (categoryId != null) {
        url += '?categoryId=$categoryId';
      }

      final response = await ApiClient.authenticatedGet(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['cards'] as List? ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ [StudyProgress] getCardsToReview error: $e');
      return [];
    }
  }

  // ==================== STREAK APIs ====================

  /// Lấy thông tin streak của user
  static Future<StudyStreakModel> getStreakInfo() async {
    try {
      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/study/streak'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StudyStreakModel.fromJson(data);
      } else {
        return StudyStreakModel.empty();
      }
    } catch (e) {
      debugPrint('❌ [StudyProgress] getStreakInfo error: $e');
      return StudyStreakModel.empty();
    }
  }

  /// Lấy dữ liệu học 7 ngày gần nhất
  static Future<List<DailyStudyModel>> getWeeklyData() async {
    try {
      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/study/weekly'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => DailyStudyModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [StudyProgress] getWeeklyData error: $e');
      return [];
    }
  }

  // ==================== REMINDER APIs ====================

  /// Lấy cài đặt nhắc nhở
  static Future<StudyReminderModel> getReminderSettings() async {
    try {
      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/study/reminder'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StudyReminderModel.fromJson(data);
      } else {
        return StudyReminderModel.defaultSettings();
      }
    } catch (e) {
      debugPrint('❌ [StudyProgress] getReminderSettings error: $e');
      return StudyReminderModel.defaultSettings();
    }
  }

  /// Cập nhật cài đặt nhắc nhở
  static Future<StudyReminderModel?> updateReminderSettings(StudyReminderModel reminder) async {
    try {
      final response = await ApiClient.authenticatedPut(
        Uri.parse('${ApiConfig.baseUrl}/api/study/reminder'),
        body: reminder.toJson(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StudyReminderModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [StudyProgress] updateReminderSettings error: $e');
      return null;
    }
  }

  /// Bật/tắt nhắc nhở
  static Future<bool> toggleReminder(bool enabled) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/study/reminder/toggle'),
        body: {'enabled': enabled},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [StudyProgress] toggleReminder error: $e');
      return false;
    }
  }

  // ==================== LOCAL STORAGE ====================

  /// Lưu reminder settings vào local (backup khi offline)
  static Future<void> saveReminderLocally(StudyReminderModel reminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('study_reminder', json.encode(reminder.toJson()));
    } catch (e) {
      debugPrint('❌ [StudyProgress] saveReminderLocally error: $e');
    }
  }

  /// Lấy reminder settings từ local
  static Future<StudyReminderModel?> getReminderLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('study_reminder');
      if (data != null) {
        return StudyReminderModel.fromJson(json.decode(data));
      }
      return null;
    } catch (e) {
      debugPrint('❌ [StudyProgress] getReminderLocally error: $e');
      return null;
    }
  }

  /// Lưu FCM token
  static Future<void> saveFcmToken(String token) async {
    try {
      final response = await ApiClient.authenticatedPut(
        Uri.parse('${ApiConfig.baseUrl}/api/study/reminder'),
        body: {'fcmToken': token},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [StudyProgress] FCM token saved');
      }
    } catch (e) {
      debugPrint('❌ [StudyProgress] saveFcmToken error: $e');
    }
  }
}