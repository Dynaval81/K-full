import 'package:flutter/material.dart';
import '../constants/palette.dart';

/// Knoty branded themes — light and dark.
/// Both use KPalette.gold as the primary accent.
class AppTheme {
  // ── Dark surface tokens ───────────────────────────────────────────────────
  static const Color _darkBg          = Color(0xFF0F0F0F);
  static const Color _darkSurface     = Color(0xFF1C1C1C);
  static const Color _darkSurfaceHigh = Color(0xFF282828);
  static const Color _darkOnSurface   = Color(0xFFF2F2F2);
  static const Color _darkSubtext     = Color(0xFF9E9E9E);
  static const Color _darkDivider     = Color(0xFF2E2E2E);

  static ThemeData get lightTheme {
    const cs = ColorScheme.light(
      primary:              KPalette.gold,
      onPrimary:            KPalette.ink,
      secondary:            KPalette.goldMid,
      onSecondary:          KPalette.ink,
      error:                KPalette.error,
      onError:              Colors.white,
      surface:              KPalette.white,
      onSurface:            KPalette.ink,
      onSurfaceVariant:     KPalette.subtext,
      outline:              KPalette.border,
      surfaceContainerLow:  KPalette.surface,
      surfaceContainer:     Color(0xFFEDEDED),
    );

    return ThemeData(
      colorScheme:            cs,
      brightness:             Brightness.light,
      scaffoldBackgroundColor: KPalette.surface,
      cardColor:              KPalette.white,
      dividerColor:           KPalette.border,
      appBarTheme: const AppBarTheme(
        backgroundColor:  KPalette.white,
        elevation:        0,
        scrolledUnderElevation: 0,
        iconTheme:        IconThemeData(color: KPalette.ink),
        titleTextStyle:   TextStyle(
          color: KPalette.ink, fontSize: 18, fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge:  TextStyle(color: KPalette.ink,     fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: KPalette.ink,     fontWeight: FontWeight.w600),
        bodyLarge:   TextStyle(color: KPalette.ink),
        bodyMedium:  TextStyle(color: KPalette.subtext),
        labelMedium: TextStyle(color: KPalette.subtext),
        labelSmall:  TextStyle(color: KPalette.hint),
      ),
      iconTheme: const IconThemeData(color: KPalette.ink),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KPalette.gold,
          foregroundColor: KPalette.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? KPalette.gold : KPalette.disabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? KPalette.gold.withOpacity(0.4)
              : KPalette.border,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const cs = ColorScheme.dark(
      primary:              KPalette.gold,
      onPrimary:            KPalette.ink,
      secondary:            KPalette.goldMid,
      onSecondary:          KPalette.ink,
      error:                Color(0xFFFF6B6B),
      onError:              Colors.black,
      surface:              _darkSurface,
      onSurface:            _darkOnSurface,
      onSurfaceVariant:     _darkSubtext,
      outline:              _darkDivider,
      surfaceContainerLow:  _darkBg,
      surfaceContainer:     _darkSurfaceHigh,
    );

    return ThemeData(
      colorScheme:             cs,
      brightness:              Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      cardColor:               _darkSurface,
      dividerColor:            _darkDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor:  _darkSurface,
        elevation:        0,
        scrolledUnderElevation: 0,
        iconTheme:        IconThemeData(color: _darkOnSurface),
        titleTextStyle:   TextStyle(
          color: _darkOnSurface, fontSize: 18, fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge:  TextStyle(color: _darkOnSurface, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: _darkOnSurface, fontWeight: FontWeight.w600),
        bodyLarge:   TextStyle(color: _darkOnSurface),
        bodyMedium:  TextStyle(color: _darkSubtext),
        labelMedium: TextStyle(color: _darkSubtext),
        labelSmall:  TextStyle(color: _darkSubtext),
      ),
      iconTheme: const IconThemeData(color: _darkOnSurface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KPalette.gold,
          foregroundColor: KPalette.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? KPalette.gold : _darkSubtext,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? KPalette.gold.withOpacity(0.35)
              : _darkDivider,
        ),
      ),
    );
  }
}
