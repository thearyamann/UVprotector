import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class AdviceCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;

  const AdviceCard({super.key, required this.uvData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final advice = uvData?.exposureAdvice ?? 'Tap refresh to get your UV data.';
    final risk = uvData?.riskLevel;
    final color = AppTheme.riskColor(risk);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(isDark),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              border: Border.all(color: color.withOpacity(0.2), width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.wb_sunny_outlined, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advice, style: AppTheme.bodyPrimary(isDark)),
                if (uvData != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    uvData!.spfRecommendation,
                    style: AppTheme.bodySecondary(isDark),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
