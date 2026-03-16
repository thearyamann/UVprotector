import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class ProtectionCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;

  const ProtectionCard({super.key, required this.uvData, required this.isDark});

  String _extractSpf(String spf) {
    if (spf == '—') return '—';
    final match = RegExp(r'SPF\s[\d–]+').firstMatch(spf);
    return match?.group(0) ?? spf;
  }

  @override
  Widget build(BuildContext context) {
    final spf = uvData?.spfRecommendation ?? '—';
    final spfShort = _extractSpf(spf);
    final blue = AppTheme.brandBlue(isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROTECTION', style: AppTheme.labelSmall(isDark)),
          const SizedBox(height: 10),
          Text(
            spfShort,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(isDark),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text('Recommended', style: AppTheme.bodySecondary(isDark)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: blue.withValues(alpha: 0.1),
          border: Border.all(color: blue.withValues(alpha: 0.2), width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Apply now',
              style: TextStyle(
                fontSize: 10,
                color: blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
