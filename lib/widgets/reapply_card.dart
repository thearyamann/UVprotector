import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';



class ReapplyCard extends StatelessWidget {
  final UVData? uvData;
  final VoidCallback? onReapplied;

  const ReapplyCard({
    super.key,
    required this.uvData,
    this.onReapplied,
  });

  double _progress(int? reapplyMinutes) {
    if (reapplyMinutes == null) return 0;
    return (reapplyMinutes / 180).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final reapply  = uvData?.reapplyMinutes;
    final spf      = uvData?.spfRecommendation ?? 'SPF recommended';
    final progress = _progress(reapply);

    return Container(
      height: 168,
      decoration: AppTheme.cardDecoration,
      child: Stack(
        children: [
  
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.access_time, size: 12, color: Color(0xFF888888)),
                      SizedBox(width: 5),
                      Text('REAPPLY TIMER', style: AppTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reapply != null ? '$reapply min left' : '— min left',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a2332),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(spf, style: AppTheme.bodySecondary),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFF0F0F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.ctaGreen),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onReapplied,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.ctaGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Mark as reapplied',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ctaGreenText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          
        ],
      ),
    );
  }
}