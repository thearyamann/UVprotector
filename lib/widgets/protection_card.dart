import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class ProtectionCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;
  const ProtectionCard({super.key, required this.uvData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final uvIndex = uvData?.uvIndex ?? -1;
    final noUV = uvData != null && uvIndex <= 0;

    String mainText, subText, infoText;
    Color mainColor;

    if (uvData == null) {
      mainText = '--';
      subText = 'Loading...';
      infoText = '';
      mainColor = AppTheme.textPrimary(isDark);
    } else if (noUV) {
      mainText = 'None';
      subText = 'No sunscreen needed';
      infoText = 'UV index is 0';
      mainColor = const Color(0xFF16A34A);
    } else {
      final spf = uvData!.spfRecommendation;
      final match = RegExp(r'SPF\s[\d–]+').firstMatch(spf);
      mainText = match?.group(0) ?? spf;
      subText = 'Recommended';
      infoText = 'Broad spectrum';
      mainColor = AppTheme.textPrimary(isDark);
    }

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
              Text('PROTECTION', style: AppTheme.labelSmall(isDark)),
              const SizedBox(height: 7),
              Text(
                mainText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: mainColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(subText, style: AppTheme.bodySecondary(isDark)),
              if (infoText.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  infoText,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: noUV
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF0369A1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
