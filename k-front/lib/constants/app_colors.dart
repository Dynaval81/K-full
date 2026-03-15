import 'package:flutter/material.dart';
export 'palette.dart'; // KPalette — use this in new code

/// Legacy color constants — kept for backward compatibility with
/// app_theme.dart, settings_screen.dart, register_screen.dart.
/// New screens should use KPalette from palette.dart instead.
class AppColors {
  // Dark theme (vtalk legacy — used only in AppTheme.darkTheme)
  static const Color primaryBackground = Color(0xFF1A1A2E);
  static const Color cardBackground    = Color(0xFF252541);
  static const Color primaryText       = Colors.white;
  static const Color secondaryText     = Colors.white70;

  // Light theme
  static const Color lightPrimaryBackground = Color(0xFFF5F5F5);
  static const Color lightCardBackground    = Color(0xFFFFFFFF);
  static const Color lightPrimaryText       = Color(0xFF1A1A1A);
  static const Color lightSecondaryText     = Color(0xFF666666);

  // Accent (still referenced in settings_screen and app_theme)
  static const Color primaryBlue = Color(0xFF2196F3);

  // Text helpers
  static const Color greyText = Color(0xFF757575);

  // Borders
  static const Color lightPrimaryBorder = Color(0xFFE0E0E0);

  // Aliases used in main.dart / shared widgets (point to light values; prefer Theme.of(context) in new code)
  static const Color surface   = lightCardBackground;
  static const Color onSurface = lightPrimaryText;
  static const Color onSurfaceVariant = lightSecondaryText;
}
