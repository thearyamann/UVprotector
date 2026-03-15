import 'package:flutter/material.dart';
import '../../models/skin_type.dart';



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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.85)
              : Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B7DD8)
                : Colors.white.withOpacity(0.85),
            width: isSelected ? 2 : 0.5,
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
            Text(
              'Type ${skinType.type}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a2332),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              // Show just the first word e.g. "Very" or "Fair"
              skinType.description.split('—').first.trim().split(' ').first,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF6a7a8a),
              ),
            ),
          ],
        ),
      ),
    );
  }
}