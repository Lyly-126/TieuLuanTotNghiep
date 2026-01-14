import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:src_app/utils/navigation_logger.dart';
import 'dart:async';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'services/deep_link_service.dart';
import 'services/local_notification_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';

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
  ApiConfig.setNgrokUrl('https://backend-52ab.onrender.com');
  // ApiConfig.setNgrokUrl('https://isochoric-subrostral-audie.ngrok-free.dev');
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

    if (state == AppLifecycleState.resumed) {
      // ✅ Khi app resume từ background, verify auth status
      _verifyAuthOnResume();
    }
  }

  Future<void> _verifyAuthOnResume() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      print('📱 App resumed - Auth status: $isLoggedIn');

      if (!isLoggedIn) {
        // Token hết hạn hoặc bị xóa - đá về login
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
      // ✅ THAY ĐỔI: Bắt đầu từ SplashScreen thay vì welcome
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}