import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../theme/app_theme.dart';
import 'skeleton_loader.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData? weatherData;
  final bool isDark;
  const WeatherCard({super.key, required this.weatherData, required this.isDark});

  IconData _icon(String c) {
    final s = c.toLowerCase();
    if (s.contains('clear') || s.contains('sunny')) return Icons.wb_sunny_rounded;
    if (s.contains('partly'))  return Icons.wb_cloudy_outlined;
    if (s.contains('cloud'))   return Icons.cloud_rounded;
    if (s.contains('rain') || s.contains('shower')) return Icons.grain_rounded;
    if (s.contains('snow'))    return Icons.ac_unit_rounded;
    if (s.contains('storm'))   return Icons.thunderstorm_rounded;
    if (s.contains('fog'))     return Icons.blur_on_rounded;
    return Icons.wb_sunny_outlined;
  }

  Color _color(String c) {
    final s = c.toLowerCase();
    if (s.contains('clear') || s.contains('sunny')) return const Color(0xFFFF9800);
    if (s.contains('partly')) return const Color(0xFFFFB74D);
    if (s.contains('rain') || s.contains('shower')) return const Color(0xFF42A5F5);
    if (s.contains('storm')) return const Color(0xFF7E57C2);
    if (s.contains('snow'))  return const Color(0xFF90CAF9);
    return const Color(0xFF78909C);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: AppTheme.cardDecoration(isDark),
          child: weatherData == null ? _skeleton() : _content(),
        ),
      ),
    );
  }

  Widget _skeleton() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonBox(width: 60, height: 9, radius: 4, isDark: isDark),
      const SizedBox(height: 9),
      SkeletonBox(width: 40, height: 28, radius: 6, isDark: isDark),
      const SizedBox(height: 6),
      SkeletonBox(width: 70, height: 10, radius: 4, isDark: isDark),
      const Spacer(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        SkeletonBox(width: 26, height: 8, radius: 3, isDark: isDark),
        SkeletonBox(width: 26, height: 8, radius: 3, isDark: isDark),
      ]),
    ],
  );

  Widget _content() {
    final temp      = weatherData!.temperature.round().toString();
    final high      = weatherData!.high.round().toString();
    final low       = weatherData!.low.round().toString();
    final condition = weatherData!.condition;
    final city      = weatherData!.cityName;
    final color     = _color(condition);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.location_on_outlined, size: 9, color: AppTheme.textMuted(isDark)),
          const SizedBox(width: 3),
          Expanded(child: Text(city.toUpperCase(),
              style: AppTheme.labelSmall(isDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 5),
        Text('$temp°', style: TextStyle(
            fontSize: 30, fontWeight: FontWeight.w300,
            color: AppTheme.textPrimary(isDark), height: 1)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(_icon(condition), size: 11, color: color),
          const SizedBox(width: 3),
          Expanded(child: Text(condition, style: TextStyle(
              fontSize: 9.5, fontWeight: FontWeight.w500, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('H $high°', style: TextStyle(fontSize: 8.5, color: AppTheme.textMuted(isDark))),
          Text('L $low°',  style: TextStyle(fontSize: 8.5, color: AppTheme.textMuted(isDark))),
        ]),
      ],
    );
  }
}