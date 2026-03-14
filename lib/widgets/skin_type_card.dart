import 'package:flutter/material.dart';
import '../models/skin_type.dart';
import '../theme/app_theme.dart';


class SkinTypeCard extends StatelessWidget {
  final SkinType selectedSkinType;
  final VoidCallback onTap;

  const SkinTypeCard({
    super.key,
    required this.selectedSkinType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('SKIN TYPE', style: AppTheme.labelSmall),
                Icon(Icons.touch_app_outlined, size: 12, color: Color(0xFFBBBBBB)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${selectedSkinType.type}', style: AppTheme.numberLarge),
            const SizedBox(height: 4),
            Text(
              selectedSkinType.description.split('—').first.trim(),
              style: const TextStyle(fontSize: 13, color: AppTheme.brandBlue, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
           
            Row(
              children: SkinType.all.map((s) {
                final isActive = s.type == selectedSkinType.type;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 3),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isActive ? AppTheme.brandBlue : const Color(0xFFE8E8E8),
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
              style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}