import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class BurnTimeCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;

  const BurnTimeCard({super.key, required this.uvData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final burn    = uvData?.burnTimeMinutes;
    final risk    = uvData?.riskLevel;
    final color   = AppTheme.riskColor(risk);
    final display = burn == null ? '--'
        : burn == double.infinity ? '∞'
        : burn.toStringAsFixed(0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BURN TIME', style: AppTheme.labelSmall(isDark)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: display, style: AppTheme.numberMedium(isDark)),
                TextSpan(text: ' min', style: AppTheme.unitText(isDark)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            risk != null ? '$risk risk' : '—',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}