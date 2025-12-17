import 'package:flutter/material.dart';

class AppConstants {
  // ✅ Padding constants
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;

  // Padding chuẩn cho toàn màn hình
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);

  // Padding phụ
  static const EdgeInsets horizontalPaddingSmall = EdgeInsets.symmetric(horizontal: 16);

  // Spacing chuẩn giữa các phần
  static const double sectionSpacingSmall = 16;
  static const double sectionSpacingMedium = 24;
  static const double sectionSpacingLarge = 40;

  // ✅ Border radius
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 16.0;

  // Input
  static const double inputPadding = 16;
  static const double labelSpacing = 8; // khoảng cách label → input

  // Kích thước hình minh họa (welcome, empty states,...)
  static const double illustrationWidth = 250;

  // ✅ API Base URL
  static const String baseUrl = 'http://localhost:8080';

  // ✅ Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  // ✅ Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // ✅ Card elevation
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 4.0;
}