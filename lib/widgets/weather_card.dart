import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData? weatherData;
  final bool isDark;

  const WeatherCard({super.key, required this.weatherData, required this.isDark});

  IconData _icon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('clear') || c.contains('sunny')) return Icons.wb_sunny_rounded;
    if (c.contains('partly'))                        return Icons.wb_cloudy_outlined;
    if (c.contains('cloud'))                         return Icons.cloud_rounded;
    if (c.contains('rain') || c.contains('shower'))  return Icons.grain_rounded;
    if (c.contains('snow'))                          return Icons.ac_unit_rounded;
    if (c.contains('storm'))                         return Icons.thunderstorm_rounded;
    if (c.contains('fog'))                           return Icons.blur_on_rounded;
    return Icons.wb_sunny_outlined;
  }

  Color _color(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('clear') || c.contains('sunny')) return const Color(0xFFFF9800);
    if (c.contains('partly'))                        return const Color(0xFFFFB74D);
    if (c.contains('rain') || c.contains('shower'))  return const Color(0xFF42A5F5);
    if (c.contains('storm'))                         return const Color(0xFF7E57C2);
    if (c.contains('snow'))                          return const Color(0xFF90CAF9);
    return const Color(0xFF78909C);
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration(isDark),
          child: weatherData == null
              ? _buildSkeleton(sh)
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildSkeleton(double sh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 70, height: 10, radius: 5, isDark: isDark),
        const SizedBox(height: 10),
        SkeletonBox(width: 70, height: 10, radius: 5, isDark: isDark),
        const SizedBox(height: 8),
       SkeletonBox(width: 70, height: 10, radius: 5, isDark: isDark),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SkeletonBox(width: 30, height: 9, radius: 3, isDark: isDark),
            SkeletonBox(width: 30, height: 9, radius: 3, isDark: isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    final temp      = weatherData!.temperature.round().toString();
    final high      = weatherData!.high.round().toString();
    final low       = weatherData!.low.round().toString();
    final condition = weatherData!.condition;
    final city      = weatherData!.cityName;
    final color     = _color(condition);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 10, color: AppTheme.textMuted(isDark)),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                city.toUpperCase(),
                style: AppTheme.labelSmall(isDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$temp°',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w300,
            color: AppTheme.textPrimary(isDark),
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(_icon(condition), size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                condition,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('H $high°', style: TextStyle(fontSize: 9, color: AppTheme.textMuted(isDark))),
            Text('L $low°',  style: TextStyle(fontSize: 9, color: AppTheme.textMuted(isDark))),
          ],
        ),
      ],
    );
  }
}