import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

class UVIndexCard extends StatelessWidget {
  final UVData? uvData;
  final bool isDark;

  const UVIndexCard({super.key, required this.uvData, required this.isDark});

  double _barPosition(double uvIndex) => (uvIndex / 11).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final uv     = uvData?.uvIndex;
    final risk   = uvData?.riskLevel;
    final color  = AppTheme.riskColor(risk);
    final barPos = uv != null ? _barPosition(uv) : 0.0;

    return Pressable(
      scaleDown: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('UV INDEX', style: AppTheme.labelSmall(isDark)),
                Icon(Icons.north_east, size: 11, color: AppTheme.textMuted(isDark)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              uv != null ? uv.toStringAsFixed(0) : '--',
              style: AppTheme.numberLarge(isDark),
            ),
            const SizedBox(height: 3),
            Text(
              risk ?? '—',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 10,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned.fill(
                    top: 3, bottom: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4CAF50),
                            Color(0xFFFFEB3B),
                            Color(0xFFFF9800),
                            Color(0xFFFF5722),
                            Color(0xFFE91E63),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(
                      (barPos * 2 - 1).clamp(-1.0, 0.95), 0),
                    child: Container(
                      width: 9, height: 9,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1a2a3a) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Peak:', style: TextStyle(fontSize: 9, color: AppTheme.textMuted(isDark))),
                Text('12:00–15:00', style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary(isDark),
                  fontWeight: FontWeight.w500,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}