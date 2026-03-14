import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color bgPage = Color(0xFFE8F0F7); // light blue page
  static const Color bgCard = Colors.white;

  static const Color brandBlue = Color(0xFF3B7DD8);

  static const Color ctaGreen = Color(0xFFA8D971);
  static const Color ctaGreenText = Color(0xFF2d5a1b);

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

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    color: Color(0xFF888888),
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle numberLarge = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w300,
    color: Color(0xFF1a2332),
    height: 1,
  );

  static const TextStyle numberMedium = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w300,
    color: Color(0xFF1a2332),
    height: 1,
  );

  static const TextStyle bodyPrimary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1a2332),
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 11,
    color: Color(0xFF888888),
  );

  static const TextStyle unitText = TextStyle(
    fontSize: 13,
    color: Color(0xFFAAAAAA),
    fontWeight: FontWeight.w400,
  );

  
  static BoxDecoration get cardDecoration =>
      BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20));


  static const double cardGap = 10;
  static const double pageHPad = 16;
}
