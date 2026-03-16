import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class ProtectionCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;

  const ProtectionCard({super.key, required this.uvData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final uvIndex  = uvData?.uvIndex ?? -1;
    final noUV     = uvData != null && uvIndex <= 0;
    final blue     = AppTheme.brandBlue(isDark);

    String mainText;
    String subText;
    String infoText;
    Color  mainColor;

    if (uvData == null) {
      mainText  = '--';
      subText   = 'Loading...';
      infoText  = '';
      mainColor = AppTheme.textPrimary(isDark);
    } else if (noUV) {
      mainText  = 'None';
      subText   = 'No sunscreen needed';
      infoText  = 'UV index is 0';
      mainColor = const Color(0xFF16A34A);
    } else {
      final spf   = uvData!.spfRecommendation;
      final match = RegExp(r'SPF\s[\d–]+').firstMatch(spf);
      mainText  = match?.group(0) ?? spf;
      subText   = 'Recommended';
      infoText  = 'Broad spectrum';
      mainColor = AppTheme.textPrimary(isDark);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROTECTION', style: AppTheme.labelSmall(isDark)),
          const SizedBox(height: 8),
          Text(
            mainText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: mainColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(subText, style: AppTheme.bodySecondary(isDark)),
          if (infoText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              infoText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: noUV ? const Color(0xFF16A34A) : blue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}