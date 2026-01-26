import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:src_app/utils/navigation_logger.dart';
import 'dart:async';
import 'dart:io';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'services/deep_link_service.dart';
import 'services/local_notification_service.dart';
import 'services/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    print('🌐 Running on WEB');
    print('ℹ️ Deep Links & Local Notifications disabled on Web');
  } else {
    print('📱 Running on Mobile');

    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    try {
      await LocalNotificationService.init();

      // ✅ Set navigator key
      LocalNotificationService.setNavigatorKey(navigatorKey);

      print('✅ Local Notifications initialized');

      await Future.delayed(Duration(seconds: 1));
      // await LocalNotificationService.testNotification();
      // print('🧪 Test notification sent!');

    } catch (e) {
      print('⚠️ Local Notifications init error: $e');
    }
  }

  ApiConfig.setNgrokUrl('https://backend-52ab.onrender.com');
  ApiConfig.printConfig();

  runApp(const FlaiApp());
}

Future<void> _requestAndroidPermissions() async {
  try {
    // Import flutter_local_notifications để access Android plugin
    final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Request notification permission (Android 13+)
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      print('📲 Notification permission: $notifGranted');

      // Request exact alarm permission (Android 12+)
      final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
      print('⏰ Exact alarm permission: $alarmGranted');
    }
  } catch (e) {
    print('⚠️ Permission request error: $e');
  }
}

class FlaiApp extends StatefulWidget {
  const FlaiApp({super.key});

  @override
  State<FlaiApp> createState() => _FlaiAppState();
}

class _FlaiAppState extends State<FlaiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    print('🚀 FlaiApp: Initializing...');

    WidgetsBinding.instance.addObserver(this);

    if (!kIsWeb) {
      _initDeepLinks();
    }
  }

  Future<void> _initDeepLinks() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await DeepLinkService.init();
      print('✅ Deep Links initialized');
    } catch (e) {
      print('⚠️ Deep Links init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('📱 App lifecycle state: $state');

    if (state == AppLifecycleState.resumed) {
      _verifyAuthOnResume();
    }
  }

  Future<void> _verifyAuthOnResume() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      print('📱 App resumed - Auth status: $isLoggedIn');

      if (!isLoggedIn) {
        print('⚠️ Auth token invalid, redirecting to login...');
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
              (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error verifying auth on resume: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (!kIsWeb) {
      DeepLinkService.dispose();
    }

    print('👋 FlaiApp: Disposing...');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flai',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [NavigationLogger()],
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}