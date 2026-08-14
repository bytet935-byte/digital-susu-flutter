import 'package:flutter/material.dart';

/// Digital Susu V2 brand palette — per the supplied design reference
/// (docs/DESIGN.md): blue `#2563EB` primary, green `#10B981`, orange
/// `#F59E0B`, red `#EF4444`, gray `#687280`, light gray `#F3F4F6`.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2563EB); // reference blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF10B981); // reference green
  static const Color secondaryContainer = Color(0xFFD1FAE5);
  static const Color onSecondary = Color(0xFF064E3B);

  /// Deep navy used by splash screen and hero balance cards (reference).
  static const Color navy = Color(0xFF1E3A8A);

  // Neutrals
  static const Color background = Color(0xFFF3F4F6); // reference light gray
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF687280); // reference gray
  static const Color outline = Color(0xFFE5E7EB);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF2563EB);

  // Money — used to visually distinguish financial amounts (reference uses
  // green for positive/credit, red for negative/debit).
  static const Color moneyPositive = Color(0xFF10B981);
  static const Color moneyNegative = Color(0xFFEF4444);
}
