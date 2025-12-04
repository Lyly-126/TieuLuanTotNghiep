import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
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
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial link (app opened from link)
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Handle links while app is running
    _linkSubscription = linkStream.listen((String? link) {
      if (link != null) {
        _handleDeepLink(link);
      }
    });
  }

  void _handleDeepLink(String link) {
    print('🔗 Received deep link: $link');

    // Parse: flai://join/ABC123
    final uri = Uri.parse(link);

    if (uri.scheme == 'flai' && uri.host == 'join') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final inviteCode = pathSegments[0];
        print('📝 Invite code: $inviteCode');

        // Navigate to join class screen
        navigatorKey.currentState?.pushNamed(
          AppRoutes.join_class,
          arguments: inviteCode,
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey, // ✅ Thêm này
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}