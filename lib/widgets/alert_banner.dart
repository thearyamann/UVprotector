import 'package:flutter/material.dart';
import 'pressable.dart';

class UVAlertBanner extends StatelessWidget {
  final double uvIndex;
  final bool isDark;
  final VoidCallback onApplyTap;

  const UVAlertBanner({
    super.key,
    required this.uvIndex,
    required this.isDark,
    required this.onApplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UV is ${uvIndex >= 8 ? "Very High" : "High"} — not protected!',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You haven't applied sunscreen yet. UV index is ${uvIndex.toStringAsFixed(0)}.",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF9a5a5a)),
                ),
                const SizedBox(height: 8),
                Pressable(
                  onTap: onApplyTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Apply sunscreen now',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}