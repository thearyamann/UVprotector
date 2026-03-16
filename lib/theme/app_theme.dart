import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const List<Color> lightGradient = [
    Color(0xFFFFEEDD),
    Color(0xFFE8F0F7),
    Color(0xFFDDEEFF),
    Color(0xFFD4EED8),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF1a0f2e),
    Color(0xFF0d1f3c),
    Color(0xFF0a2240),
    Color(0xFF0d2518),
  ];

  static Color cardBg(bool isDark) =>
      isDark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF);

  static Color cardBorder(bool isDark) =>
      isDark ? const Color(0x24FFFFFF) : const Color(0xBFFFFFFF);

  static BoxDecoration cardDecoration(bool isDark) => BoxDecoration(
    color: cardBg(isDark),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: cardBorder(isDark), width: 0.5),
  );

  static Color textPrimary(bool isDark) =>
      isDark ? const Color(0xF2FFFFFF) : const Color(0xFF1e2b3a);

  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0x80FFFFFF) : const Color(0xFF5a6a7a);

  static Color textLabel(bool isDark) =>
      isDark ? const Color(0x66FFFFFF) : const Color(0xFF7a8a96);

  static Color textMuted(bool isDark) =>
      isDark ? const Color(0x59FFFFFF) : const Color(0xFF9aabb5);

  static Color brandBlue(bool isDark) =>
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B7DD8);

  static Color riskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return const Color(0xFF4CAF50);
      case 'Moderate':
        return const Color(0xFFFFC107);
      case 'High':
        return const Color(0xFFFF6B35);
      case 'Very High':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  static Color ctaBg(bool isDark) =>
      isDark ? const Color(0x1F4ADE80) : const Color(0x2E8CC850);

  static Color ctaBorder(bool isDark) =>
      isDark ? const Color(0x404ADE80) : const Color(0x3864AA32);

  static Color ctaText(bool isDark) =>
      isDark ? const Color(0xFF4ADE80) : const Color(0xFF3a7818);

  static Color progressTrack(bool isDark) =>
      isDark ? const Color(0x14FFFFFF) : const Color(0x4DB4C3D2);

  static TextStyle labelSmall(bool isDark) => TextStyle(
    fontSize: 10,
    color: textLabel(isDark),
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
  );

  static TextStyle numberLarge(bool isDark) => TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w300,
    color: textPrimary(isDark),
    height: 1,
  );

  static TextStyle numberMedium(bool isDark) => TextStyle(
    fontSize: 30,
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
    fontSize: 13,
    color: textMuted(isDark),
    fontWeight: FontWeight.w400,
  );

  static const Color bgPage = Color(0xFFE8F0F7);
  static const Color bgCard = Colors.white;
  static const Color ctaGreen = Color(0xFFA8D971);
  static const Color ctaGreenText = Color(0xFF2d5a1b);
  static const double cardGap = 10;
  static const double pageHPad = 16;
}
