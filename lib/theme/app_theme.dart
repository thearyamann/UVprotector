import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const List<Color> lightGradient = [
    Color(0xFFE0D0BC),
    Color(0xFFE0E7F2),
    Color(0xFFF5F5F5),
    Color(0xFFCFE3D6),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF000000), // Pure Black
    Color(0xFF1e1e1e), // Very Dark Grey
    Color(0xFF1e1e1e),
    Color(0xFF1e1e1e),
  ];

  static Color cardBg(bool isDark) =>
      isDark ? const Color(0x1AFFFFFF) : const Color(0xB8FFFFFF);

  static Color cardBorder(bool isDark) =>
      isDark ? const Color(0x14FFFFFF) : const Color(0xE0FFFFFF);

  static Color skeletonBase(bool isDark) =>
      isDark ? const Color(0x18FFFFFF) : const Color(0xFFE2E8EF);

  static Color skeletonShimmer(bool isDark) =>
      isDark ? const Color(0x28FFFFFF) : const Color(0xFFF0F4F8);

  static BoxDecoration cardDecoration(bool isDark) => BoxDecoration(
    color: cardBg(isDark),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: cardBorder(isDark), width: 0.5),
    boxShadow: isDark
        ? null
        : [
            BoxShadow(
              color: const Color(0x0D000000),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
  );

  static Color textPrimary(bool isDark) =>
      isDark ? const Color(0xF2FFFFFF) : const Color(0xFF1a2332);

  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0x80FFFFFF) : const Color(0xFF4a5a6a);

  static Color textLabel(bool isDark) =>
      isDark ? const Color(0x66FFFFFF) : const Color(0xFF6a7a8a);

  static Color textMuted(bool isDark) =>
      isDark ? const Color(0x59FFFFFF) : const Color(0xFF8a9aaa);

  static Color brandBlue(bool isDark) =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  // Compatibility alias used by existing widget code.
  static Color brandGreen(bool isDark) => ctaText(isDark);

  static Color riskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return const Color(0xFF16A34A);
      case 'Moderate':
        return const Color(0xFFD97706);
      case 'High':
        return const Color(0xFFF9741B);
      case 'Very High':
        return const Color(0xFFF9741B);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  static Color ctaBg(bool isDark) =>
      isDark ? const Color(0x1F4ADE80) : const Color(0x2514532D);

  static Color ctaBorder(bool isDark) =>
      isDark ? const Color(0x404ADE80) : const Color(0x4515803D);

  static Color ctaText(bool isDark) =>
      isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D);
  static Color progressTrack(bool isDark) =>
      isDark ? const Color(0x14FFFFFF) : const Color(0x40B4C3D2);

  static TextStyle labelSmall(bool isDark) => TextStyle(
    fontSize: 10,
    color: textLabel(isDark),
    letterSpacing: 0.6,
    fontWeight: FontWeight.w600,
  );

  static TextStyle numberLarge(bool isDark) => TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w300,
    color: textPrimary(isDark),
    height: 1,
  );

  static TextStyle numberMedium(bool isDark) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    color: textPrimary(isDark),
    height: 1,
  );

  static TextStyle bodyPrimary(bool isDark) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textPrimary(isDark),
  );

  static TextStyle bodySecondary(bool isDark) =>
      TextStyle(fontSize: 11, color: textMuted(isDark));

  static TextStyle unitText(bool isDark) => TextStyle(
    fontSize: 12,
    color: textMuted(isDark),
    fontWeight: FontWeight.w400,
  );

  static const Color bgPage = Color(0xFFEAEEF4);
  static const Color bgCard = Colors.white;
  static const Color ctaGreen = Color(0xFFA8D971);
  static const Color ctaGreenText = Color(0xFF2d5a1b);
  static const double cardGap = 10;
  static const double pageHPad = 16;
}
