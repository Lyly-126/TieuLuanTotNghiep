import 'package:flutter/material.dart';

class AppConstants {
  // Padding chuẩn cho toàn màn hình
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24);

  // Padding phụ
  static const EdgeInsets horizontalPaddingSmall = EdgeInsets.symmetric(horizontal: 16);

  // Spacing chuẩn giữa các phần
  static const double sectionSpacingSmall = 16;
  static const double sectionSpacingMedium = 24;
  static const double sectionSpacingLarge = 40;

  // Input
  static const double borderRadius = 12;
  static const double inputPadding = 16;
  static const double labelSpacing = 8; // khoảng cách label → input

  // Kích thước hình minh họa (welcome, empty states,...)
  static const double illustrationWidth = 250;

  static const String baseUrl = 'http://localhost:8080';
}
