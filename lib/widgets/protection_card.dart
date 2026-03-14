import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../theme/app_theme.dart';

class ProtectionCard extends StatelessWidget {
  final UVData? uvData;

  const ProtectionCard({super.key, required this.uvData});

  @override
  Widget build(BuildContext context) {
    final spf = uvData?.spfRecommendation ?? '—';

    final spfShort = spf.split(' ').take(2).join(' ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROTECTION', style: AppTheme.labelSmall),
          const SizedBox(height: 10),
          Text(
            spfShort,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1a2332),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Recommended', style: AppTheme.bodySecondary),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Apply now',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF2d7a3a),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
