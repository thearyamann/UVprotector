import 'package:flutter/material.dart';
import '../../models/skin_type.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';



class SkinTypeCard extends StatelessWidget {
  final SkinType skinType;
  final bool isSelected;
  final VoidCallback onTap;


  static const List<Color> _skinColors = [
    Color(0xFFFFD4B8),
    Color(0xFFF0B090),
    Color(0xFFC8835A),
    Color(0xFFA0622E),
    Color(0xFF6B3E1A),
    Color(0xFF2E1A0E),
  ];

  const SkinTypeCard({
    super.key,
    required this.skinType,
    required this.isSelected,
    required this.onTap,
  });

  Color get _dotColor => _skinColors[skinType.type - 1];

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeController.of(context).isDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : AppTheme.cardBorder(isDark),
            width: isSelected ? 2.0 : 0.8,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Text(
              // Show descriptive skin color name
              skinType.description.split('—').first.trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}