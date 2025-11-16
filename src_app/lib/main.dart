import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'config/app_theme.dart';

void main() {
  runApp(const FlaiApp());
}

class FlaiApp extends StatelessWidget {
  const FlaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
    );
  }
}
