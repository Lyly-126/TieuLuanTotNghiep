import 'package:flutter/material.dart';

class AppColors {
  // 🎯 Màu chính (theo Figma)
  static const Color primary = Color(0xFF22C55E);      // Xanh lá nút chính
  static const Color primaryDark = Color(0xFF064E3B);  // Xanh đậm cho tiêu đề, label
  static const Color primaryLight = Color(0xFFD1FAE5); // Xanh nhạt
  static const Color accent = Color(0xFF16A34A);       // Xanh sáng cho link

  // ✅ Secondary color
  static const Color secondary = Color(0xFF3B82F6);    // Xanh dương
  static const Color secondaryDark = Color(0xFF1E40AF);
  static const Color secondaryLight = Color(0xFFDEEBFF);

  // 🧩 Nền và input
  static const Color inputBackground = Color(0xFFF0FDF4); // nền ô nhập
  static const Color background = Color(0xFFF9FAFB);      // nền app xám nhạt
  static const Color surface = Colors.white;               // nền card/surface trắng

  // 🖋️ Màu chữ theo hierarchy Figma
  static const Color textPrimary = Color(0xFF064E3B);   // màu chữ chính
  static const Color textSecondary = Color(0xFF374151); // chữ phụ
  static const Color textGray = Color(0xFF9CA3AF);      // chữ gợi ý/hint
  static const Color textLight = Color(0xFFD1D5DB);     // chữ nhạt

  // ✅ Icon colors
  static const Color icon = Color(0xFF9CA3AF);          // xám nhẹ dễ nhìn
  static const Color iconDark = Color(0xFF374151);

  // ✅ Border & Divider
  static const Color border = Color(0xFFE5E7EB);        // màu viền
  static const Color divider = Color(0xFFE5E7EB);       // màu divider

  // ✅ Status colors
  static const Color success = Color(0xFF10B981);       // màu thành công (xanh lá)
  static const Color error = Color(0xFFEF4444);         // màu lỗi (đỏ)
  static const Color warning = Color(0xFFF59E0B);       // màu cảnh báo (vàng)
  static const Color info = Color(0xFF3B82F6);          // màu thông tin (xanh dương)

  // ✅ Overlay colors
  static const Color overlay = Color(0x80000000);       // Overlay đen 50%
  static const Color overlayLight = Color(0x40000000);  // Overlay đen 25%

  // ✅ Disabled colors
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color disabledText = Color(0xFF9CA3AF);

  // ✅ Shadow color
  static const Color shadow = Color(0x1A000000);        // Shadow nhẹ
}