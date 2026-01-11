import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import '../models/category_study_schedule_model.dart';

/// ✅ Service quản lý lịch học theo Category
/// Sử dụng API /api/category-reminder đã có sẵn trong backend
class CategoryStudyScheduleService {
  static const String _localStorageKey = 'category_study_schedules';

  // ==================== API CALLS ====================

  /// Lấy lịch học của một category
  static Future<CategoryStudyScheduleModel?> getSchedule(int categoryId) async {
    try {
      debugPrint('📡 [ScheduleService] Getting schedule for category $categoryId');

      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminder/$categoryId'),
      );

      debugPrint('📥 [ScheduleService] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('📥 [ScheduleService] Data: $data');
        return CategoryStudyScheduleModel.fromCategoryReminderJson(data);
      }

      // Nếu chưa có schedule (404), trả về model mặc định
      if (response.statusCode == 404) {
        debugPrint('📭 [ScheduleService] No schedule found, returning default');
        return CategoryStudyScheduleModel(categoryId: categoryId);
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ScheduleService] getSchedule error: $e');
      // Thử lấy từ local storage
      return await _getScheduleLocally(categoryId);
    }
  }

  /// Lấy tất cả lịch học của user
  static Future<List<CategoryStudyScheduleModel>> getAllSchedules() async {
    try {
      debugPrint('📡 [ScheduleService] Getting all schedules');

      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminder'),
      );

      debugPrint('📥 [ScheduleService] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => CategoryStudyScheduleModel.fromCategoryReminderJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ScheduleService] getAllSchedules error: $e');
      // Thử lấy từ local storage
      return await _getAllSchedulesLocally();
    }
  }

  /// Lấy các lịch học đang bật
  static Future<List<CategoryStudyScheduleModel>> getActiveSchedules() async {
    try {
      debugPrint('📡 [ScheduleService] Getting active schedules');

      final response = await ApiClient.authenticatedGet(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminder/active'),
      );

      debugPrint('📥 [ScheduleService] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // ✅ API trả về object { count, reminders } hoặc List trực tiếp
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['reminders'] != null) {
          data = decoded['reminders'] as List;
          debugPrint('📥 [ScheduleService] Found ${decoded['count']} reminders in response');
        } else {
          debugPrint('📭 [ScheduleService] Unexpected response format');
          return [];
        }

        final schedules = data
            .map((e) => CategoryStudyScheduleModel.fromCategoryReminderJson(e as Map<String, dynamic>))
            .toList();

        debugPrint('✅ [ScheduleService] Parsed ${schedules.length} active schedules');
        return schedules;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ScheduleService] getActiveSchedules error: $e');
      return [];
    }
  }

  /// Cập nhật lịch học
  static Future<CategoryStudyScheduleModel?> updateSchedule(
      CategoryStudyScheduleModel schedule,
      ) async {
    try {
      debugPrint('📡 [ScheduleService] Updating schedule for category ${schedule.categoryId}');
      debugPrint('📡 [ScheduleService] Data: ${schedule.toCategoryReminderJson()}');

      final response = await ApiClient.authenticatedPut(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminder/${schedule.categoryId}'),
        body: schedule.toCategoryReminderJson(),
      );

      debugPrint('📥 [ScheduleService] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updated = CategoryStudyScheduleModel.fromCategoryReminderJson(data);

        // Lưu local backup
        await _saveScheduleLocally(updated);

        return updated;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ScheduleService] updateSchedule error: $e');
      // Lưu local và sync sau
      await _saveScheduleLocally(schedule);
      return schedule;
    }
  }

  /// Xóa lịch học
  static Future<bool> deleteSchedule(int categoryId) async {
    try {
      final response = await ApiClient.authenticatedDelete(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminder/$categoryId'),
      );

      if (response.statusCode == 200) {
        await _removeScheduleLocally(categoryId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [ScheduleService] deleteSchedule error: $e');
      return false;
    }
  }

  /// Bật/tắt lịch học
  static Future<bool> toggleSchedule(int categoryId, bool enabled) async {
    try {
      final response = await ApiClient.authenticatedPost(
        Uri.parse('${ApiConfig.baseUrl}/api/category-reminder/$categoryId/toggle'),
        body: {},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [ScheduleService] toggleSchedule error: $e');
      return false;
    }
  }

  // ==================== CONFLICT DETECTION ====================

  /// Phát hiện xung đột lịch học
  static Future<List<ScheduleConflict>> detectConflicts(
      List<CategoryStudyScheduleModel> schedules,
      ) async {
    List<ScheduleConflict> conflicts = [];

    // Chỉ xét các schedule đang bật
    final activeSchedules = schedules.where((s) => s.isEnabled).toList();

    // Group by time slot (hour:minute + dayOfWeek)
    Map<String, List<CategoryStudyScheduleModel>> timeSlots = {};

    for (var schedule in activeSchedules) {
      for (int day = 0; day < 7; day++) {
        if (schedule.isDayEnabled(day)) {
          final key = '${schedule.hour}:${schedule.minute}:$day';
          timeSlots.putIfAbsent(key, () => []);
          timeSlots[key]!.add(schedule);
        }
      }
    }

    // Tìm các slot có nhiều hơn 1 schedule
    for (var entry in timeSlots.entries) {
      if (entry.value.length > 1) {
        final parts = entry.key.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dayOfWeek = int.parse(parts[2]);

        conflicts.add(ScheduleConflict(
          hour: hour,
          minute: minute,
          dayOfWeek: dayOfWeek,
          categories: entry.value.map((s) => ConflictingCategory(
            categoryId: s.categoryId,
            categoryName: s.categoryName ?? 'Học phần ${s.categoryId}',
          )).toList(),
        ));
      }
    }

    return conflicts;
  }

  /// Kiểm tra xem schedule mới có xung đột không
  static Future<List<ScheduleConflict>> checkNewScheduleConflicts(
      CategoryStudyScheduleModel newSchedule,
      List<CategoryStudyScheduleModel>? existingSchedules,
      ) async {
    // Lấy existing schedules nếu chưa có
    existingSchedules ??= await getAllSchedules();

    // Loại bỏ schedule cũ của cùng category (nếu đang update)
    final otherSchedules = existingSchedules
        .where((s) => s.categoryId != newSchedule.categoryId)
        .toList();

    // Thêm schedule mới vào danh sách
    final allSchedules = [...otherSchedules, newSchedule];

    return detectConflicts(allSchedules);
  }

  // ==================== SCHEDULE OVERVIEW ====================

  /// Lấy tổng quan lịch học (hiển thị trên home screen)
  static Future<StudyScheduleOverview> getScheduleOverview() async {
    try {
      debugPrint('📡 [ScheduleService] Getting schedule overview...');

      final schedules = await getActiveSchedules();

      if (schedules.isEmpty) {
        debugPrint('📭 [ScheduleService] No active schedules found');
        return StudyScheduleOverview.empty();
      }

      final now = DateTime.now();
      // Convert từ Dart weekday (1=T2, 7=CN) sang index (0=CN, 1=T2, ...)
      final todayDayOfWeek = now.weekday % 7; // 7%7=0 (CN), 1=T2, 2=T3...

      debugPrint('📅 [ScheduleService] Today: ${now.toString()}, weekday=${now.weekday}, dayIndex=$todayDayOfWeek');

      // Lịch học hôm nay
      List<ScheduleItem> todaySchedules = [];
      for (var schedule in schedules) {
        debugPrint('📅 [ScheduleService] Checking schedule: categoryId=${schedule.categoryId}, daysOfWeek=${schedule.daysOfWeek}');
        debugPrint('📅 [ScheduleService] isDayEnabled($todayDayOfWeek) = ${schedule.isDayEnabled(todayDayOfWeek)}');

        if (schedule.isDayEnabled(todayDayOfWeek)) {
          todaySchedules.add(ScheduleItem(
            categoryId: schedule.categoryId,
            categoryName: schedule.categoryName ?? 'Học phần ${schedule.categoryId}',
            hour: schedule.hour,
            minute: schedule.minute,
            dayOfWeek: todayDayOfWeek,
            scheduledDateTime: DateTime(
              now.year, now.month, now.day,
              schedule.hour, schedule.minute,
            ),
          ));
          debugPrint('✅ [ScheduleService] Added today schedule: ${schedule.categoryName} at ${schedule.displayTime}');
        }
      }

      // Sắp xếp theo thời gian
      todaySchedules.sort((a, b) => a.compareTime(b));
      debugPrint('📅 [ScheduleService] Today schedules count: ${todaySchedules.length}');

      // Lịch học sắp tới (7 ngày)
      List<ScheduleItem> upcomingSchedules = [];
      for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
        final futureDate = now.add(Duration(days: dayOffset));
        final futureDayOfWeek = futureDate.weekday % 7;

        for (var schedule in schedules) {
          if (schedule.isDayEnabled(futureDayOfWeek)) {
            upcomingSchedules.add(ScheduleItem(
              categoryId: schedule.categoryId,
              categoryName: schedule.categoryName ?? 'Học phần ${schedule.categoryId}',
              hour: schedule.hour,
              minute: schedule.minute,
              dayOfWeek: futureDayOfWeek,
              scheduledDateTime: DateTime(
                futureDate.year, futureDate.month, futureDate.day,
                schedule.hour, schedule.minute,
              ),
            ));
          }
        }
      }

      debugPrint('📅 [ScheduleService] Upcoming schedules count: ${upcomingSchedules.length}');

      // Phát hiện xung đột
      final conflicts = await detectConflicts(schedules);

      final overview = StudyScheduleOverview(
        todaySchedules: todaySchedules,
        upcomingSchedules: upcomingSchedules,
        conflicts: conflicts,
        totalActiveSchedules: schedules.length,
      );

      debugPrint('✅ [ScheduleService] Overview created: total=${overview.totalActiveSchedules}, today=${overview.todaySchedules.length}, upcoming=${overview.upcomingSchedules.length}');

      return overview;
    } catch (e) {
      debugPrint('❌ [ScheduleService] getScheduleOverview error: $e');
      return StudyScheduleOverview.empty();
    }
  }

  /// Lấy schedule tiếp theo (cho notification)
  static Future<ScheduleItem?> getNextSchedule() async {
    try {
      final overview = await getScheduleOverview();
      final now = DateTime.now();

      // Tìm trong lịch hôm nay
      for (var item in overview.todaySchedules) {
        if (item.scheduledDateTime != null &&
            item.scheduledDateTime!.isAfter(now)) {
          return item;
        }
      }

      // Nếu không có hôm nay, lấy từ upcoming
      if (overview.upcomingSchedules.isNotEmpty) {
        return overview.upcomingSchedules.first;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ScheduleService] getNextSchedule error: $e');
      return null;
    }
  }

  // ==================== LOCAL STORAGE ====================

  static Future<void> _saveScheduleLocally(CategoryStudyScheduleModel schedule) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allSchedules = await _getAllSchedulesLocally();

      // Update hoặc add
      final index = allSchedules.indexWhere((s) => s.categoryId == schedule.categoryId);
      if (index >= 0) {
        allSchedules[index] = schedule;
      } else {
        allSchedules.add(schedule);
      }

      final jsonList = allSchedules.map((s) => s.toJson()).toList();
      await prefs.setString(_localStorageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ [ScheduleService] _saveScheduleLocally error: $e');
    }
  }

  static Future<CategoryStudyScheduleModel?> _getScheduleLocally(int categoryId) async {
    try {
      final allSchedules = await _getAllSchedulesLocally();
      return allSchedules.cast<CategoryStudyScheduleModel?>().firstWhere(
            (s) => s?.categoryId == categoryId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint('❌ [ScheduleService] _getScheduleLocally error: $e');
      return null;
    }
  }

  static Future<List<CategoryStudyScheduleModel>> _getAllSchedulesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_localStorageKey);
      if (data != null) {
        final List jsonList = json.decode(data);
        return jsonList.map((e) => CategoryStudyScheduleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ScheduleService] _getAllSchedulesLocally error: $e');
      return [];
    }
  }

  static Future<void> _removeScheduleLocally(int categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allSchedules = await _getAllSchedulesLocally();
      allSchedules.removeWhere((s) => s.categoryId == categoryId);

      final jsonList = allSchedules.map((s) => s.toJson()).toList();
      await prefs.setString(_localStorageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ [ScheduleService] _removeScheduleLocally error: $e');
    }
  }

  /// Xóa tất cả local data
  static Future<void> clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);
    } catch (e) {
      debugPrint('❌ [ScheduleService] clearLocalData error: $e');
    }
  }

  /// Sync local data với server
  static Future<void> syncWithServer() async {
    try {
      final localSchedules = await _getAllSchedulesLocally();
      for (var schedule in localSchedules) {
        await updateSchedule(schedule);
      }
      debugPrint('✅ [ScheduleService] Synced ${localSchedules.length} schedules');
    } catch (e) {
      debugPrint('❌ [ScheduleService] syncWithServer error: $e');
    }
  }
}