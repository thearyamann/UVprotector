import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class BurnTimeCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;

  const BurnTimeCard({super.key, required this.uvData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final burn = uvData?.burnTimeMinutes;
    final risk = uvData?.riskLevel;
    final color = AppTheme.riskColor(risk);

    final bool isUnlimited = burn == double.infinity;
    final bool noData = burn == null;

    final ({String value, String unit}) burnDisplay = _buildBurnDisplay(
      burn,
      noData: noData,
      isUnlimited: isUnlimited,
    );

    final String riskText = noData
        ? '—'
        : isUnlimited
        ? 'No burn risk'
        : '$risk risk';

    final Color riskColor = isUnlimited ? const Color(0xFF16A34A) : color;

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
                TextSpan(
                  text: burnDisplay.value,
                  style: TextStyle(
                    fontSize: isUnlimited ? 26 : 28,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textPrimary(isDark),
                    height: 1,
                  ),
                ),
                if (burnDisplay.unit.isNotEmpty)
                  TextSpan(
                    text: burnDisplay.unit,
                    style: AppTheme.unitText(isDark),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            riskText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }

  ({String value, String unit}) _buildBurnDisplay(
    double? burn, {
    required bool noData,
    required bool isUnlimited,
  }) {
    if (noData) return (value: '--', unit: '');
    if (isUnlimited) return (value: 'Safe', unit: ' all day');

    final totalMinutes = burn!.round();
    if (totalMinutes < 60) {
      return (value: '$totalMinutes', unit: ' min');
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return (value: '$hours', unit: ' hr');
    }

    return (value: '$hours hr', unit: ' $minutes min');
  }
}
