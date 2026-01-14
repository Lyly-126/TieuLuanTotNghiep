// File: lib/services/local_notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../routes/app_routes.dart';

/// Service quản lý Local Notifications
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ✅ THÊM: Static navigator key (không phụ thuộc main.dart)
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // Notification Channel IDs
  static const String _studyChannelId = 'study_reminders';
  static const String _generalChannelId = 'general';

  /// Khởi tạo service
  static Future<void> init() async {
    if (_initialized) return;

    print('🔔 LocalNotificationService: Initializing...');

    // Khởi tạo timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Khởi tạo plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // Tạo notification channels cho Android
    await _createNotificationChannels();

    // Request permissions
    await _requestPermissions();

    _initialized = true;
    print('✅ LocalNotificationService: Initialized successfully');
  }

  /// Tạo notification channels cho Android
  static Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Channel cho Study Reminders
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _studyChannelId,
        'Nhắc nhở học tập',
        description: 'Thông báo nhắc nhở học tập hàng ngày',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Channel cho General notifications
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _generalChannelId,
        'Thông báo chung',
        description: 'Thông báo chung từ ứng dụng',
        importance: Importance.defaultImportance,
      ),
    );

    print('✅ Notification channels created');
  }

  /// Request permissions
  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Request notification permission (Android 13+)
      await androidPlugin?.requestNotificationsPermission();

      // Request exact alarm permission (Android 12+)
      await androidPlugin?.requestExactAlarmsPermission();
    }

    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Xử lý khi tap vào notification (foreground)
  static void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  /// Xử lý khi tap vào notification (background)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    print('🔔 Background notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  /// Xử lý payload của notification
  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    final parts = payload.split(':');
    if (parts.length < 2) return;

    final type = parts[0];
    final id = parts[1];

    // ✅ FIX: Sử dụng local navigator key
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      print('⚠️ Navigator not available');
      return;
    }

    switch (type) {
      case 'category':
        navigator.pushNamed(
          AppRoutes.categoryDetail,
          arguments: {'categoryId': int.tryParse(id)},
        );
        break;

      case 'class':
        navigator.pushNamed(
          AppRoutes.class_detail,
          arguments: int.tryParse(id),
        );
        break;

      case 'quiz':
        navigator.pushNamed(
          AppRoutes.flashcard,
          arguments: {'categoryId': int.tryParse(id)},
        );
        break;

      default:
        print('⚠️ Unknown notification type: $type');
    }
  }

  // ==================== SHOW NOTIFICATIONS ====================

  /// Hiển thị notification ngay lập tức
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = _generalChannelId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _studyChannelId ? 'Nhắc nhở học tập' : 'Thông báo chung',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4CAF50),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
    print('✅ Notification shown: $title');
  }

  /// Hiển thị notification nhắc nhở học tập
  static Future<void> showStudyReminder({
    required int categoryId,
    required String categoryName,
    String? customMessage,
  }) async {
    await showNotification(
      id: categoryId,
      title: '📚 Đến giờ học $categoryName!',
      body: customMessage ?? 'Hãy dành ít phút ôn tập "$categoryName" nhé!',
      payload: 'category:$categoryId',
      channelId: _studyChannelId,
    );
  }

  // ==================== SCHEDULED NOTIFICATIONS ====================

  /// Lên lịch notification theo thời gian cụ thể
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = _generalChannelId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _studyChannelId ? 'Nhắc nhở học tập' : 'Thông báo chung',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    print('✅ Scheduled notification: $title at $scheduledTime');
  }

  /// Lên lịch nhắc nhở học tập hàng ngày
  static Future<void> scheduleDailyStudyReminder({
    required int id,
    required String categoryName,
    required int categoryId,
    required TimeOfDay time,
    String? customMessage,
    List<int>? daysOfWeek, // 1=Mon, 7=Sun (null = everyday)
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Nếu thời gian đã qua trong ngày, lên lịch cho ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _studyChannelId,
      'Nhắc nhở học tập',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4CAF50),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule repeating notification
    await _notifications.zonedSchedule(
      id,
      '📚 Đến giờ học $categoryName!',
      customMessage ?? 'Hãy dành ít phút ôn tập "$categoryName" nhé!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp lại hàng ngày
      payload: 'category:$categoryId',
    );

    print('✅ Scheduled daily reminder for $categoryName at ${time.hour}:${time.minute}');
  }

  /// Lên lịch nhắc nhở theo các ngày trong tuần
  static Future<void> scheduleWeeklyReminder({
    required int baseId,
    required String categoryName,
    required int categoryId,
    required TimeOfDay time,
    required List<int> daysOfWeek, // 1=Mon, 7=Sun
    String? customMessage,
  }) async {
    // Hủy các notification cũ
    for (var day in [1, 2, 3, 4, 5, 6, 7]) {
      await cancelNotification(baseId + day);
    }

    // Lên lịch cho từng ngày được chọn
    for (var day in daysOfWeek) {
      final notificationId = baseId + day;

      final now = DateTime.now();
      var scheduledDate = _getNextDayOfWeek(day, time);

      final androidDetails = AndroidNotificationDetails(
        _studyChannelId,
        'Nhắc nhở học tập',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notificationId,
        '📚 Đến giờ học $categoryName!',
        customMessage ?? 'Hãy dành ít phút ôn tập "$categoryName" nhé!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'category:$categoryId',
      );
    }

    print('✅ Scheduled weekly reminders for $categoryName on days: $daysOfWeek');
  }

  /// Lấy ngày tiếp theo trong tuần
  static DateTime _getNextDayOfWeek(int dayOfWeek, TimeOfDay time) {
    final now = DateTime.now();
    var daysUntilTarget = dayOfWeek - now.weekday;

    if (daysUntilTarget < 0) {
      daysUntilTarget += 7;
    } else if (daysUntilTarget == 0) {
      // Nếu là hôm nay, kiểm tra xem thời gian đã qua chưa
      final targetTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (targetTime.isBefore(now)) {
        daysUntilTarget = 7;
      }
    }

    return DateTime(
      now.year,
      now.month,
      now.day + daysUntilTarget,
      time.hour,
      time.minute,
    );
  }

  // ==================== CANCEL NOTIFICATIONS ====================

  /// Hủy một notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('✅ Cancelled notification: $id');
  }

  /// Hủy tất cả notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('✅ Cancelled all notifications');
  }

  /// Hủy notifications của một category
  static Future<void> cancelCategoryNotifications(int categoryId) async {
    // Hủy daily reminder
    await cancelNotification(categoryId);

    // Hủy weekly reminders (baseId + 1-7)
    for (var day = 1; day <= 7; day++) {
      await cancelNotification(categoryId * 10 + day);
    }

    print('✅ Cancelled all notifications for category: $categoryId');
  }

  // ==================== UTILITIES ====================

  /// Kiểm tra xem có pending notifications không
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Test notification
  static Future<void> testNotification() async {
    await showNotification(
      id: 999,
      title: '🧪 Test Notification',
      body: 'Local notification đang hoạt động!',
      payload: 'test:0',
    );
  }
}