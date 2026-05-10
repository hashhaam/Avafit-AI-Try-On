import 'package:flutter/material.dart';

class AppColors {
  // Core
  static const Color background = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF1C1C1E);
  static const Color secondaryText = Color(0xFF8E8E93);

  // Brand
  static const Color purple = Color(0xFF8F6BFF);
  static const Color blue = Color(0xFF5B7CFA);

  // UI
  static const Color inputBackground = Color(0xFFF4F4F6);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF9C6BFF),
      Color(0xFF6A8CFF),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
