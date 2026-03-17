import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /// Green gradient header 
  static const List<Color> greenGradient = [
    Color(0xFF0f3320),
    Color(0xFF1a5c35),
    Color(0xFF22774a),
  ];

  // ── Page backgrounds 
  static const Color lightBg = Color(0xFFF2F5F2);
  static const Color darkBg  = Color(0xFF0d1a0f);

  // ── Card ───────────────────────────────────────────────
  static Color cardBg(bool isDark) => isDark
      ? const Color(0x12FFFFFF)
      : const Color(0x99FFFFFF);

  static Color cardBorder(bool isDark) => isDark
      ? const Color(0x1FFFFFFF)
      : const Color(0xF0FFFFFF);

  static BoxDecoration cardDecoration(bool isDark) => BoxDecoration(
    color: cardBg(isDark),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: cardBorder(isDark), width: 0.5),
  );

  // ── Skeleton shimmer ───────────────────────────────────
  static Color skeletonBase(bool isDark) => isDark
      ? const Color(0x18FFFFFF)
      : const Color(0xFFDDE4DD);

  static Color skeletonShimmer(bool isDark) => isDark
      ? const Color(0x28FFFFFF)
      : const Color(0xFFEDF2ED);

  // ── Text ───────────────────────────────────────────────
  static Color textPrimary(bool isDark) => isDark
      ? const Color(0xF0FFFFFF)
      : const Color(0xFF1a2a1a);

  static Color textSecondary(bool isDark) => isDark
      ? const Color(0x80FFFFFF)
      : const Color(0xFF4a5a4a);

  static Color textLabel(bool isDark) => isDark
      ? const Color(0x60FFFFFF)
      : const Color(0xFF7a8a7a);

  static Color textMuted(bool isDark) => isDark
      ? const Color(0x45FFFFFF)
      : const Color(0xFF9aaa9a);

  // ── Brand / accent ─────────────────────────────────────
  static Color brandGreen(bool isDark) => isDark
      ? const Color(0xFF4ADE80)
      : const Color(0xFF1a5c35);

  // ── CTA compatibility colors (legacy references) ───────
  static Color ctaBg(bool isDark) => brandGreen(isDark);

  static Color ctaBorder(bool isDark) =>
      brandGreen(isDark).withValues(alpha: isDark ? 0.55 : 0.35);

  static Color ctaText(bool isDark) =>
      isDark ? const Color(0xFF05210F) : const Color(0xFFFFFFFF);

  // kept for any legacy references
  static Color brandBlue(bool isDark) => isDark
      ? const Color(0xFF4ADE80)
      : const Color(0xFF1a5c35);

  // ── Risk colours ───────────────────────────────────────
  static Color riskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'Low':       return const Color(0xFF16A34A);
      case 'Moderate':  return const Color(0xFFD97706);
      case 'High':      return const Color(0xFFEA580C);
      case 'Very High': return const Color(0xFFDC2626);
      default:          return const Color(0xFF7C3AED);
    }
  }

  // ── Black button ───────────────────────────────────────
  static BoxDecoration blackBtn() => BoxDecoration(
    color: const Color(0xD9141414),
    borderRadius: BorderRadius.circular(12),
  );

  // ── Progress track ─────────────────────────────────────
  static Color progressTrack(bool isDark) => isDark
      ? const Color(0x14FFFFFF)
      : const Color(0x30000000);

  // ── Text styles ────────────────────────────────────────
  static TextStyle labelSmall(bool isDark) => TextStyle(
    fontSize: 9.5,
    color: textLabel(isDark),
    letterSpacing: 0.55,
    fontWeight: FontWeight.w600,
  );

  static TextStyle numberLarge(bool isDark) => TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w300,
    color: textPrimary(isDark),
    height: 1,
  );

  static TextStyle numberMedium(bool isDark) => TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w300,
    color: textPrimary(isDark),
    height: 1,
  );

  static TextStyle bodyPrimary(bool isDark) => TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: textPrimary(isDark),
  );

  static TextStyle bodySecondary(bool isDark) =>
      TextStyle(fontSize: 10.5, color: textMuted(isDark));

  static TextStyle unitText(bool isDark) => TextStyle(
    fontSize: 11,
    color: textMuted(isDark),
    fontWeight: FontWeight.w400,
  );
}