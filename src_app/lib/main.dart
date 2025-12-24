import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  ApiConfig.setNgrokUrl('https://isochoric-subrostral-audie.ngrok-free.dev');

  // In ra config để kiểm tra
  ApiConfig.printConfig();

  runApp(const FlaiApp());
}

class FlaiApp extends StatefulWidget {
  const FlaiApp({super.key});

  @override
  State<FlaiApp> createState() => _FlaiAppState();
}

class _FlaiAppState extends State<FlaiApp> {
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    print('🚀 FlaiApp: Initializing...');
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    print('🔗 Initializing deep links...');

    // Handle initial link (app opened from link)
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        print('🔗 Initial link received: $initialLink');
        _handleDeepLink(initialLink);
      } else {
        print('ℹ️ No initial link');
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }

    // Handle links while app is running
    _linkSubscription = linkStream.listen(
          (String? link) {
        if (link != null) {
          print('🔗 Link received: $link');
          _handleDeepLink(link);
        }
      },
      onError: (err) {
        print('❌ Error in link stream: $err');
      },
    );
  }

  void _handleDeepLink(String link) {
    print('═══════════════════════════════════════');
    print('🔍 Handling deep link: $link');

    try {
      final uri = Uri.parse(link);
      print('📝 Parsed URI:');
      print('   - Scheme: ${uri.scheme}');
      print('   - Host: ${uri.host}');
      print('   - Path: ${uri.path}');
      print('   - Path segments: ${uri.pathSegments}');

      String? inviteCode;

      // Case 1: Deep link scheme - flai://join/ABC123
      if (uri.scheme == 'flai' && uri.host == 'join') {
        print('✅ Matched deep link scheme (flai://)');
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          inviteCode = pathSegments[0];
          print('✅ Extracted invite code from deep link: $inviteCode');
        } else {
          print('⚠️ No path segments in deep link');
        }
      }
      // Case 2: Ngrok/Web link - https://abc123.ngrok-free.app/join/ABC123
      else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.path.startsWith('/join/')) {
        print('✅ Matched web link (https://)');
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2 && pathSegments[0] == 'join') {
          inviteCode = pathSegments[1];
          print('✅ Extracted invite code from web link: $inviteCode');
        } else {
          print('⚠️ Invalid path format: ${uri.path}');
        }
      } else {
        print('⚠️ Unknown link format');
      }

      if (inviteCode != null && inviteCode.isNotEmpty) {
        print('🎯 Navigating to join screen with code: $inviteCode');

        // Delay navigation để đảm bảo UI đã ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = navigatorKey.currentState;
          if (navigator != null) {
            print('✅ Navigator is ready, pushing route...');
            navigator.pushNamed(
              AppRoutes.joinClass,
              arguments: inviteCode,
            );
          } else {
            print('❌ Navigator is null!');
          }
        });
      } else {
        print('❌ Could not extract invite code from: $link');
      }
    } catch (e, stackTrace) {
      print('❌ Error parsing deep link: $e');
      print('Stack trace: $stackTrace');
    }

    print('═══════════════════════════════════════');
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
      theme: AppTheme.light,
      navigatorKey: navigatorKey, // ✅ QUAN TRỌNG!
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}