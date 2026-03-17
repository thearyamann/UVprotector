import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class AdviceCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;
  const AdviceCard({super.key, required this.uvData, required this.isDark});

  IconData _iconForRisk(String? risk) {
    switch (risk) {
      case 'Low':
        return Icons.check_circle_outline_rounded;
      case 'Moderate':
        return Icons.wb_sunny_outlined;
      case 'High':
        return Icons.warning_amber_rounded;
      case 'Very High':
        return Icons.dangerous_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final advice = uvData?.exposureAdvice ?? 'Pull down to load UV data.';
    final risk = uvData?.riskLevel;
    final color = AppTheme.riskColor(risk);
    final noUV = (uvData?.uvIndex ?? -1) <= 0;
    final spf = uvData?.spfRecommendation ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: AppTheme.cardDecoration(isDark),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                  border: Border.all(
                    color: color.withValues(alpha: 0.18),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_iconForRisk(risk), size: 15, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(advice, style: AppTheme.bodyPrimary(isDark)),
                    if (uvData != null && !noUV) ...[
                      const SizedBox(height: 2),
                      Text(spf, style: AppTheme.bodySecondary(isDark)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
