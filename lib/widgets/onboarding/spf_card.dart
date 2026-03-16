import 'package:flutter/material.dart';

class SpfOption {
  final int value;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;

  const SpfOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
  });

  
  static const List<SpfOption> all = [
    SpfOption(
      value: 15,
      label: 'SPF 15',
      subtitle: 'Basic',
      iconColor: Color(0xFFFF9800),
      iconBg: Color(0x1AFF9800),
      icon: Icons.wb_sunny_outlined,
    ),
    SpfOption(
      value: 30,
      label: 'SPF 30',
      subtitle: 'Good',
      iconColor: Color(0xFF3B7DD8),
      iconBg: Color(0x1A3B7DD8),
      icon: Icons.shield_outlined,
    ),
    SpfOption(
      value: 50,
      label: 'SPF 50',
      subtitle: 'High',
      iconColor: Color(0xFF6AAF2E),
      iconBg: Color(0x1A6AAF2E),
      icon: Icons.verified_user_outlined,
    ),
    SpfOption(
      value: 100, // represents SPF 50+
      label: 'SPF 50+',
      subtitle: 'Maximum',
      iconColor: Color(0xFF7C4DFF),
      iconBg: Color(0x1A7C4DFF),
      icon: Icons.security_outlined,
    ),
  ];
}


class SpfCard extends StatelessWidget {
  final SpfOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const SpfCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B7DD8)
              : Colors.white.withValues(alpha: 0.85),
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: option.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(option.icon, color: option.iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1a2332),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option.subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6a7a8a),
              ),
            ),
          ],
        ),
      ),
    );
  }
}