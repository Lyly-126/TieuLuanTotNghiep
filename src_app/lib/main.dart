import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:src_app/utils/navigation_logger.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'services/notification_service.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set ngrok URL
  ApiConfig.setNgrokUrl('https://isochoric-subrostral-audie.ngrok-free.dev');
  ApiConfig.printConfig();

  runApp(const FlaiApp());
}

class FlaiApp extends StatefulWidget {
  const FlaiApp({super.key});

  @override
  State<FlaiApp> createState() => _FlaiAppState();
}

class _FlaiAppState extends State<FlaiApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    print('🚀 FlaiApp: Initializing...');
    _appLinks = AppLinks();
    _initDeepLinks();
    _initFirebaseMessaging(); // ← Thêm dòng này
  }

  // ==================== FIREBASE MESSAGING ====================

  Future<void> _initFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('🔔 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {

      // Get FCM token
      String? token = await messaging.getToken();
      print('🔑 FCM Token: $token');

      if (token != null) {
        // Save token to server (khi user đã login)
        await NotificationService.saveFcmToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        NotificationService.saveFcmToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground message: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // Handle message tap (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📩 Message opened app: ${message.data}');
        _handleNotificationTap(message.data);
      });

      // Check if app opened from notification
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('📩 Initial message: ${initialMessage.data}');
        _handleNotificationTap(initialMessage.data);
      }
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    // Show a snackbar or local notification
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? 'Thông báo mới'),
          action: SnackBarAction(
            label: 'Xem',
            onPressed: () => _handleNotificationTap(message.data),
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'CATEGORY_REMINDER':
        final categoryId = data['categoryId'];
        if (categoryId != null) {
          navigatorKey.currentState?.pushNamed(
            AppRoutes.categoryDetail,
            arguments: int.parse(categoryId.toString()),
          );
        }
        break;
    // Thêm các case khác nếu cần
    }
  }

  // ... phần còn lại giữ nguyên (deep links, dispose, build)

  Future<void> _initDeepLinks() async {
    // ... code hiện tại
  }

  void _handleDeepLink(String link) {
    // ... code hiện tại
  }

  @override
  void dispose() {
    print('👋 FlaiApp: Disposing...');
    _linkSubscription?.cancel();
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
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}