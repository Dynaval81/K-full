import 'package:flutter/material.dart';

/// Knoty / HAI3 design palette — single source of truth.
/// All screens should reference these constants instead of inlining hex values.
class KPalette {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color gold        = Color(0xFFE6B800);
  static const Color goldLight   = Color(0xFFFFF8E1);
  static const Color goldMid     = Color(0xFFFFD84D);

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const Color ink         = Color(0xFF1A1A1A);   // primary text
  static const Color subtext     = Color(0xFF6B6B6B);   // secondary text
  static const Color hint        = Color(0xFF9E9E9E);   // placeholder / caption
  static const Color disabled    = Color(0xFFBDBDBD);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFF5F5F5);   // card bg, chips
  static const Color border      = Color(0xFFE0E0E0);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color error       = Color(0xFFCC0000);
  static const Color errorLight  = Color(0xFFFFEBEE);
  static const Color success     = Color(0xFF43A047);
  static const Color successLight= Color(0xFFE8F5E9);
  static const Color info        = Color(0xFF5B8DEF);
  static const Color infoLight   = Color(0xFFEEF3FF);
  static const Color warning     = Color(0xFFFF7043);
  static const Color warningLight= Color(0xFFFFF3F0);
}
