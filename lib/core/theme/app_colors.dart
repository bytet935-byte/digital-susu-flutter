import 'package:flutter/material.dart';

/// Digital Susu V2 brand palette.
///
/// Derived from a Ghana-inspired fintech identity: deep green (growth,
/// savings) with gold accents (prosperity), balanced by a neutral grey scale
/// and clear semantic colors. Phase 11 will refine visuals using supplied
/// design references; the palette below is the functional baseline.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0B6B3A); // deep savings green
  static const Color primaryDark = Color(0xFF074A28);
  static const Color primaryContainer = Color(0xFFC8F0D8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFC9A227); // gold accent
  static const Color secondaryContainer = Color(0xFFF7E9B8);
  static const Color onSecondary = Color(0xFF2B2205);

  // Neutrals
  static const Color background = Color(0xFFF7F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B1F1C);
  static const Color onSurfaceVariant = Color(0xFF5B625D);
  static const Color outline = Color(0xFFD3D8D3);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE6A700);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // Money — used to visually distinguish financial amounts.
  static const Color moneyPositive = Color(0xFF2E7D32);
  static const Color moneyNegative = Color(0xFFC62828);
}
