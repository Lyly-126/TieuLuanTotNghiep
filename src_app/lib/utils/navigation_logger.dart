import 'package:flutter/material.dart';

class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('POP', route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    print('🔄 REPLACE: ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }

  void _logNavigation(String action, Route route, Route? previousRoute) {
    print('═══════════════════════════════════════');
    print('📍 Navigation $action');
    print('   Current: ${route.settings.name ?? 'Unknown'}');
    print('   Previous: ${previousRoute?.settings.name ?? 'None'}');
    print('   Arguments: ${route.settings.arguments}');
    print('═══════════════════════════════════════');
  }
}