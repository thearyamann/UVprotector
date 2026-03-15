import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class BurnTimeCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;

  const BurnTimeCard({super.key, required this.uvData, required this.isDark});

  double _progress(double? burnTime) {
    if (burnTime == null || burnTime == double.infinity) return 1.0;
    return (burnTime / 60).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final burn = uvData?.burnTimeMinutes;
    final risk = uvData?.riskLevel;
    final color = AppTheme.riskColor(risk);
    final progress = _progress(burn);
    final display = burn == null
        ? '--'
        : burn == double.infinity
        ? '∞'
        : burn.toStringAsFixed(0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 4),
          Text(
            risk != null ? '$risk risk' : '—',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.progressTrack(isDark),
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withOpacity(isDark ? 0.7 : 1.0),
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
