import 'dart:ui';
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
    final isUnlimited = burn == double.infinity;
    final noData = burn == null;

    final mainText = noData
        ? '--'
        : isUnlimited
        ? 'Safe'
        : burn.toStringAsFixed(0);
    final subText = noData
        ? ''
        : isUnlimited
        ? ' all day'
        : ' min';
    final riskText = noData
        ? '—'
        : isUnlimited
        ? 'No burn risk'
        : '$risk risk';
    final riskColor = isUnlimited ? const Color(0xFF16A34A) : color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: AppTheme.cardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BURN TIME', style: AppTheme.labelSmall(isDark)),
              const SizedBox(height: 7),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: mainText,
                      style: TextStyle(
                        fontSize: isUnlimited ? 24 : 26,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.textPrimary(isDark),
                        height: 1,
                      ),
                    ),
                    if (subText.isNotEmpty)
                      TextSpan(text: subText, style: AppTheme.unitText(isDark)),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                riskText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: riskColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
