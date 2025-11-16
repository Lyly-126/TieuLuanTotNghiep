import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // 🏷️ Tiêu đề lớn: "Đăng nhập", "Đăng ký"
  static final TextStyle title = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  // 🧭 Heading trung bình – section như "Chào nhé!", "Bộ thẻ đang học"
  static final TextStyle heading2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // 📘 Heading nhỏ – mục con như "Gợi ý cho bạn", "TOEIC 600+"
  static final TextStyle heading3 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ✅ THÊM: Heading4 cho card title
  static final TextStyle heading4 = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // 🧾 Label input: "Email", "Mật khẩu"
  static final TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // 💬 Hint text (placeholder)
  static final TextStyle hint = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textGray,
    height: 1.4,
  );

  // 🔘 Button text: "Đăng nhập", "Tiếp tục"
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.25,
  );

  // 🔗 Link nhỏ: "Quên mật khẩu", "Gửi lại mã OTP"
  static final TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
    height: 1.3,
  );

  // ✅ THÊM: Body text
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ✅ THÊM: Caption (chữ nhỏ)
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ⚠️ Text báo lỗi nhỏ
  static final TextStyle error = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.4,
  );
}