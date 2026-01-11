// ============================================================================
// 🔥 MAIN.DART - FINAL FIX CHO WEB
// ============================================================================
//
// HƯỚNG DẪN: Copy TOÀN BỘ nội dung file này và PASTE vào lib/main.dart
//
// File này:
// ✅ KHÔNG import Firebase
// ✅ KHÔNG import uni_links
// ✅ Hoạt động trên Web, Android, iOS
// ✅ Không cần tạo thêm file nào khác
//
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:src_app/utils/navigation_logger.dart';
import 'dart:async';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';

// ⚠️ KHÔNG IMPORT Firebase và uni_links ở đây
// Nếu cần dùng trên Mobile, uncomment và chạy riêng cho mobile

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log platform
  if (kIsWeb) {
    print('🌐 Running on WEB');
    print('ℹ️ Firebase & Deep Links disabled on Web');
  } else {
    print('📱 Running on Mobile');
    // TODO: Nếu cần Firebase trên mobile, khởi tạo ở đây
    // await Firebase.initializeApp();
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

class _FlaiAppState extends State<FlaiApp> {
  @override
  void initState() {
    super.initState();
    print('🚀 FlaiApp: Initializing...');
  }

  @override
  void dispose() {
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