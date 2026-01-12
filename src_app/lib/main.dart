// ============================================================================
// 🔥 MAIN.DART - VỚI DEEP LINK VÀ LOCAL NOTIFICATIONS
// ============================================================================
//
// File này:
// ✅ Deep Links cho Class và Category
// ✅ Local Notifications
// ✅ Hoạt động trên Web, Android, iOS
// ✅ Conditional imports để tránh lỗi trên Web
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:src_app/utils/navigation_logger.dart';
import 'dart:async';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';

// ✅ Import services cho mobile
import 'services/deep_link_service.dart';
import 'services/local_notification_service.dart';

// Global navigator key - dùng để navigate từ bất kỳ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log platform
  if (kIsWeb) {
    print('🌐 Running on WEB');
    print('ℹ️ Deep Links & Local Notifications disabled on Web');
  } else {
    print('📱 Running on Mobile');

    // ✅ Khởi tạo Local Notifications
    try {
      await LocalNotificationService.init();
      print('✅ Local Notifications initialized');
    } catch (e) {
      print('⚠️ Local Notifications init error: $e');
    }
  }

  // Config API
  ApiConfig.setNgrokUrl('https://isochoric-subrostral-audie.ngrok-free.dev');
  ApiConfig.printConfig();

  runApp(const FlaiApp());
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

    // Observer cho app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // ✅ Khởi tạo Deep Links (chỉ trên mobile)
    if (!kIsWeb) {
      _initDeepLinks();
    }
  }

  Future<void> _initDeepLinks() async {
    // Delay một chút để đảm bảo MaterialApp đã build xong
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

    // Có thể xử lý logic khi app resume/pause ở đây
    if (state == AppLifecycleState.resumed) {
      // App được mở lại - có thể refresh data nếu cần
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // ✅ Dispose Deep Link service
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
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}