import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_constants.dart';
import '../../widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppConstants.screenPadding,
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // 👈 quan trọng nè
              children: [
                // ---------------- Tiêu đề ----------------
                Center(
                  child: Text(
                    'Flai',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 36,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.sectionSpacingLarge),

                // ---------------- Hình minh họa ----------------
                Image.asset(
                  'assets/images/welcome.png',
                  width: AppConstants.illustrationWidth,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: AppConstants.sectionSpacingLarge),

                // ---------------- Mô tả ----------------
                Padding(
                  padding: AppConstants.horizontalPaddingSmall,
                  child: Text(
                    'Bằng việc đăng ký, bạn chấp nhận Điều khoản Dịch vụ và Chính sách Quyền riêng tư',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.hint.copyWith(height: 1.5),
                  ),
                ),

                const SizedBox(height: AppConstants.sectionSpacingLarge),

                // ---------------- Nút Đăng ký (full width) ----------------
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    icon: const Icon(
                      Icons.mail_outline,
                      color: Color(0xFF064E3B), // xanh đậm
                      size: 20,
                    ),
                    label: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF064E3B), // xanh đậm
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE5E7EB), // viền xám nhạt
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.sectionSpacingMedium),

                // ---------------- Liên kết “Đăng nhập” ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản?',
                      style: AppTextStyles.hint.copyWith(fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(
                        'Đăng nhập',
                        style: AppTextStyles.link.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
