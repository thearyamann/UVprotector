import 'package:flutter/material.dart';
import '../models/skin_type.dart';
import '../theme/app_theme.dart';

class SkinTypeCard extends StatelessWidget {
  final SkinType selectedSkinType;
  final VoidCallback onTap;
  final bool isDark;

  const SkinTypeCard({
    super.key,
    required this.selectedSkinType,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SKIN TYPE', style: AppTheme.labelSmall(isDark)),
                Icon(
                  Icons.touch_app_outlined,
                  size: 12,
                  color: AppTheme.textMuted(isDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${selectedSkinType.type}',
              style: AppTheme.numberLarge(isDark),
            ),
            const SizedBox(height: 4),
            Text(
              selectedSkinType.description.split('—').first.trim(),
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.brandBlue(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: SkinType.all.map((s) {
                final isActive = s.type == selectedSkinType.type;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 3),
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isActive
                          ? AppTheme.brandBlue(isDark)
                          : AppTheme.progressTrack(isDark),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              selectedSkinType.description.contains('—')
                  ? selectedSkinType.description.split('—').last.trim()
                  : selectedSkinType.description,
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted(isDark)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
