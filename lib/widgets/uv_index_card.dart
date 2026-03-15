import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class UVIndexCard extends StatelessWidget {
  final UVData? uvData;

  const UVIndexCard({super.key, required this.uvData});

  double _barPosition(double uvIndex) => (uvIndex / 11).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final uv = uvData?.uvIndex;
    final risk = uvData?.riskLevel;
    final color = AppTheme.riskColor(risk);
    final barPos = uv != null ? _barPosition(uv) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('UV INDEX', style: AppTheme.labelSmall),
              const Icon(Icons.north_east, size: 12, color: Color(0xFFBBBBBB)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            uv != null ? uv.toStringAsFixed(0) : '--',
            style: AppTheme.numberLarge,
          ),
          const SizedBox(height: 4),
          Text(
            risk ?? '—',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 12,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  top: 4,
                  bottom: 4,
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
                  alignment: Alignment((barPos * 2 - 1).clamp(-1.0, 0.95), 0),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Peak:',
                style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
              ),
              Text(
                '12:00–15:00',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
