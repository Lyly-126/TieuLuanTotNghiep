import 'package:flutter/material.dart';

class AppColors {
  // 🎯 Màu chính (theo Figma)
  static const Color primary = Color(0xFF22C55E);      // Xanh lá nút chính
  static const Color primaryDark = Color(0xFF064E3B);  // Xanh đậm cho tiêu đề, label
  static const Color accent = Color(0xFF16A34A);       // Xanh sáng cho link

  // 🧩 Nền và input
  static const Color inputBackground = Color(0xFFF0FDF4); // nền ô nhập
  static const Color background = Colors.white;           // nền app trắng

  // 🖋️ Màu chữ theo hierarchy Figma
  static const Color textPrimary = Color(0xFF064E3B);   // màu chữ chính
  static const Color textSecondary = Color(0xFF374151); // chữ phụ
  static const Color textGray = Color(0xFF9CA3AF);      // chữ gợi ý/hint

  static const Color icon = Color(0xFF9CA3AF); // xám nhẹ dễ nhìn

  // ✅ THÊM CÁC MÀU THIẾU
  static const Color border = Color(0xFFE5E7EB);        // màu viền
  static const Color success = Color(0xFF10B981);       // màu thành công (xanh lá)
  static const Color error = Color(0xFFEF4444);         // màu lỗi (đỏ)
  static const Color warning = Color(0xFFF59E0B);       // màu cảnh báo (vàng)
  static const Color info = Color(0xFF3B82F6);          // màu thông tin (xanh dương)
}