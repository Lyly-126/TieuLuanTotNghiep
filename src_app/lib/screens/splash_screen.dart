import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

/// ✅ SPLASH SCREEN
/// Màn hình khởi động - kiểm tra trạng thái đăng nhập
///
/// Flow:
/// 1. Hiển thị logo + animation
/// 2. Kiểm tra token trong SharedPreferences
/// 3. Navigate tới:
///    - Home/AdminHome (nếu đã đăng nhập)
///    - Welcome (nếu chưa đăng nhập)
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    print('🚀 [SplashScreen] Initializing...');

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Check login status
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    print('👋 [SplashScreen] Disposed');
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    // Delay để hiển thị splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      print('🔐 [SplashScreen] Checking login status...');

      // ✅ Kiểm tra đã đăng nhập chưa
      final isLoggedIn = await AuthService.isLoggedIn();

      print('🔐 [SplashScreen] Login status: $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn) {
        // ✅ Đã đăng nhập -> Kiểm tra role và navigate
        final user = await AuthService.getCurrentUser();

        print('👤 [SplashScreen] User: ${user?.email} (${user?.role})');

        if (!mounted) return;

        if (user != null && user.role == 'ADMIN') {
          print('✅ [SplashScreen] Admin user -> navigating to admin_home');
          Navigator.pushReplacementNamed(context, AppRoutes.admin_home);
        } else {
          print('✅ [SplashScreen] Normal user -> navigating to home');
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        // ❌ Chưa đăng nhập -> Vào Welcome
        print('❌ [SplashScreen] Not logged in -> navigating to welcome');
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    } catch (e) {
      print('❌ [SplashScreen] Error checking login status: $e');

      if (!mounted) return;

      // Lỗi -> Vào Welcome để an toàn
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo hoặc Icon app
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // App name
                const Text(
                  'Flai',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Học thông minh, nhớ lâu hơn',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}