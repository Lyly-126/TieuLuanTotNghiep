// File: lib/services/deep_link_service.dart
// ✅ SỬ DỤNG app_links THAY VÌ uni_links (hỗ trợ build APK tốt hơn)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../routes/app_routes.dart';
import '../main.dart'; // để lấy navigatorKey

/// Service xử lý Deep Links cho cả Class và Category
class DeepLinkService {
  static AppLinks? _appLinks;
  static StreamSubscription<Uri>? _linkSubscription;
  static bool _initialLinkHandled = false;

  /// Khởi tạo Deep Link listener
  static Future<void> init() async {
    print('🔗 DeepLinkService: Initializing with app_links...');

    _appLinks = AppLinks();

    // Xử lý link khi app được mở từ trạng thái đóng
    await _handleInitialLink();

    // Lắng nghe link khi app đang chạy
    _listenToLinks();
  }

  /// Xử lý link ban đầu (khi app mở từ link)
  static Future<void> _handleInitialLink() async {
    if (_initialLinkHandled || _appLinks == null) return;

    try {
      final initialLink = await _appLinks!.getInitialLink();
      if (initialLink != null) {
        print('🔗 Initial link: $initialLink');
        _initialLinkHandled = true;

        // Delay để đảm bảo app đã khởi tạo xong
        await Future.delayed(const Duration(milliseconds: 500));
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('❌ Failed to get initial link: $e');
    }
  }

  /// Lắng nghe links khi app đang chạy
  static void _listenToLinks() {
    if (_appLinks == null) return;

    _linkSubscription?.cancel();
    _linkSubscription = _appLinks!.uriLinkStream.listen(
          (Uri uri) {
        print('🔗 Received link while running: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('❌ Link stream error: $err');
      },
    );
  }

  /// Xử lý deep link
  static void _handleDeepLink(Uri uri) {
    print('🔗 Processing deep link: $uri');

    final pathSegments = uri.pathSegments;

    // Parse scheme-based links (flai://join/xxx or flai://category/xxx)
    if (uri.scheme == 'flai') {
      _handleFlaiSchemeLink(uri);
      return;
    }

    // Parse HTTPS links (https://domain.com/join/xxx or https://domain.com/category/xxx)
    if (uri.scheme == 'https' && pathSegments.isNotEmpty) {
      _handleHttpsLink(uri, pathSegments);
      return;
    }

    print('⚠️ Unknown link format: $uri');
  }

  /// Xử lý flai:// scheme links
  static void _handleFlaiSchemeLink(Uri uri) {
    final host = uri.host;
    final pathSegments = uri.pathSegments;

    print('🔗 Flai scheme - host: $host, pathSegments: $pathSegments');

    switch (host) {
      case 'join':
      // flai://join/{inviteCode} hoặc flai://join?code={inviteCode}
        String? inviteCode;
        if (pathSegments.isNotEmpty) {
          inviteCode = pathSegments[0];
        } else if (uri.queryParameters.containsKey('code')) {
          inviteCode = uri.queryParameters['code'];
        }
        if (inviteCode != null && inviteCode.isNotEmpty) {
          _navigateToJoinClass(inviteCode);
        }
        break;

      case 'category':
      // flai://category/{shareToken} hoặc flai://category?token={shareToken}
        String? shareToken;
        if (pathSegments.isNotEmpty) {
          shareToken = pathSegments[0];
        } else if (uri.queryParameters.containsKey('token')) {
          shareToken = uri.queryParameters['token'];
        }
        if (shareToken != null && shareToken.isNotEmpty) {
          _navigateToCategory(shareToken);
        }
        break;

      default:
        print('⚠️ Unknown flai:// host: $host');
    }
  }

  /// Xử lý HTTPS links
  static void _handleHttpsLink(Uri uri, List<String> pathSegments) {
    if (pathSegments.isEmpty) return;

    final firstSegment = pathSegments[0];

    print('🔗 HTTPS link - firstSegment: $firstSegment, pathSegments: $pathSegments');

    switch (firstSegment) {
      case 'join':
      // https://domain.com/join/{inviteCode}
        if (pathSegments.length > 1) {
          final inviteCode = pathSegments[1];
          _navigateToJoinClass(inviteCode);
        }
        break;

      case 'category':
      // https://domain.com/category/{shareToken}
        if (pathSegments.length > 1) {
          final shareToken = pathSegments[1];
          _navigateToCategory(shareToken);
        }
        break;

      default:
        print('⚠️ Unknown path: $firstSegment');
    }
  }

  /// Navigate đến màn hình Join Class
  static void _navigateToJoinClass(String inviteCode) {
    print('🎯 Navigating to Join Class with code: $inviteCode');

    // Đợi một chút để đảm bảo navigator đã sẵn sàng
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        final state = navigatorKey.currentState;
        if (state != null) {
          state.pushNamed(
            AppRoutes.joinClass,
            arguments: inviteCode,
          );
          print('✅ Navigation to joinClass successful');
        } else {
          print('⚠️ Navigator state is null, retrying...');
          // Thử lại sau 500ms
          Future.delayed(const Duration(milliseconds: 500), () {
            navigatorKey.currentState?.pushNamed(
              AppRoutes.joinClass,
              arguments: inviteCode,
            );
          });
        }
      } catch (e) {
        print('❌ Navigation error: $e');
      }
    });
  }

  /// Navigate đến màn hình Category (qua shareToken)
  static void _navigateToCategory(String shareToken) {
    print('🎯 Navigating to Category with token: $shareToken');

    // Đợi một chút để đảm bảo navigator đã sẵn sàng
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        final state = navigatorKey.currentState;
        if (state != null) {
          state.pushNamed(
            AppRoutes.categoryByToken,
            arguments: shareToken,
          );
          print('✅ Navigation to categoryByToken successful');
        } else {
          print('⚠️ Navigator state is null, retrying...');
          // Thử lại sau 500ms
          Future.delayed(const Duration(milliseconds: 500), () {
            navigatorKey.currentState?.pushNamed(
              AppRoutes.categoryByToken,
              arguments: shareToken,
            );
          });
        }
      } catch (e) {
        print('❌ Navigation error: $e');
      }
    });
  }

  /// Dispose resources
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _appLinks = null;
    print('🔗 DeepLinkService: Disposed');
  }
}