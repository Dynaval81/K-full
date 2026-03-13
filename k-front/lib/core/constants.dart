import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00A3FF);
  static const Color onPrimary = Colors.white;
  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF121212);
  static const Color onSurfaceVariant = Color(0xFF757575);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00A3FF), Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  /// Titles — minimum 22px (HAI3).
  static const TextStyle h3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );
  /// Body — minimum 16px (HAI3).
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle input = TextStyle(
    fontSize: 16,
    color: AppColors.onSurface,
  );
}

class AppSpacing {
  static const double screenPadding = 20.0;
  static const double buttonPadding = 16.0;
  static const double inputPadding = 12.0;
}

class AppBorderRadius {
  static const double button = 24.0;
  static const double input = 24.0;
}

class AppShadows {
  // 4% черный — почти незаметная дымка
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 2),
    blurRadius: 10,
  );
  // 8% черный — для кнопок и полей
  static const BoxShadow md = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: -4,
  );
  // 12% черный — глубокая тень для парящих элементов
  static const BoxShadow xl = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 16),
    blurRadius: 40,
    spreadRadius: -10,
  );
}
