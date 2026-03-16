import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../theme/app_theme.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData? weatherData;
  final bool isDark;

  const WeatherCard({super.key, required this.weatherData, required this.isDark});

  String _conditionIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('clear') || c.contains('sunny')) return '☀️';
    if (c.contains('partly'))                        return '⛅';
    if (c.contains('cloud'))                         return '☁️';
    if (c.contains('rain') || c.contains('shower'))  return '🌧️';
    if (c.contains('snow'))                          return '❄️';
    if (c.contains('storm'))                         return '⛈️';
    if (c.contains('fog'))                           return '🌫️';
    return '🌤️';
  }

  Color _conditionColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('clear') || c.contains('sunny')) return const Color(0xFFFF9800);
    if (c.contains('partly'))                        return const Color(0xFFFFB74D);
    if (c.contains('rain') || c.contains('shower'))  return const Color(0xFF42A5F5);
    if (c.contains('storm'))                         return const Color(0xFF7E57C2);
    return const Color(0xFF78909C);
  }

  @override
  Widget build(BuildContext context) {
    final temp      = weatherData?.temperature.round().toString() ?? '--';
    final high      = weatherData?.high.round().toString() ?? '--';
    final low       = weatherData?.low.round().toString() ?? '--';
    final condition = weatherData?.condition ?? '—';
    final city      = weatherData?.cityName ?? '—';
    final color     = weatherData != null ? _conditionColor(condition) : AppTheme.textMuted(isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 9, color: AppTheme.textMuted(isDark)),
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
          const SizedBox(height: 8),
          Text(
            '$temp°',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: AppTheme.textPrimary(isDark),
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                _conditionIcon(condition),
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(width: 4),
              Text(
                condition,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('H $high°', style: TextStyle(fontSize: 9, color: AppTheme.textMuted(isDark))),
              Text('L $low°',  style: TextStyle(fontSize: 9, color: AppTheme.textMuted(isDark))),
            ],
          ),
        ],
      ),
    );
  }
}