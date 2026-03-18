import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';




class WeatherService {
  static String _conditionFromCode(int code) {
    if (code == 0)             return 'Clear';
    if (code <= 3)             return 'Partly cloudy';
    if (code <= 48)            return 'Foggy';
    if (code <= 67)            return 'Rainy';
    if (code <= 77)            return 'Snowy';
    if (code <= 82)            return 'Showers';
    return 'Stormy';
  }

  static String _formatHour12(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ap = hour < 12 ? 'AM' : 'PM';
    return '$h:00 $ap';
  }

  /// Fetches weather data AND hourly UV AND current UV. Returns weather data + peak UV hours + current UV.
  static Future<({WeatherData weather, String peakStart, String peakEnd, double currentUV})> fetchWeatherAndPeak({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weathercode,uv_index'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&hourly=uv_index'
      '&timezone=auto&forecast_days=1',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather fetch failed: ${response.statusCode}');
    }

    final data    = jsonDecode(response.body);
    final current = data['current'];
    final daily   = data['daily'];
    final currentUV = (current['uv_index'] as num?)?.toDouble() ?? 0.0;

    // Parse peak UV hours from hourly data
    String peakStart = '12:00 PM';
    String peakEnd   = '3:00 PM';

    final hourly = data['hourly'];
    if (hourly != null && hourly['uv_index'] != null) {
      final uvList = (hourly['uv_index'] as List).map((e) => (e as num).toDouble()).toList();
      
      if (uvList.isNotEmpty) {
        // Find max UV value
        double maxUV = 0;
        for (final v in uvList) {
          if (v > maxUV) maxUV = v;
        }
        
        // Find the continuous window where UV >= 80% of max (the "peak" band)
        final threshold = maxUV * 0.8;
        int startHour = -1;
        int endHour = -1;
        for (int i = 0; i < uvList.length && i < 24; i++) {
          if (uvList[i] >= threshold && uvList[i] > 0) {
            if (startHour == -1) startHour = i;
            endHour = i;
          }
        }
        
        if (startHour >= 0 && endHour >= 0) {
          peakStart = _formatHour12(startHour);
          peakEnd   = _formatHour12(endHour + 1); // end is exclusive
        }
      }
    }

    final weather = WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      high:        (daily['temperature_2m_max'][0] as num).toDouble(),
      low:         (daily['temperature_2m_min'][0] as num).toDouble(),
      condition:   _conditionFromCode(current['weathercode'] as int),
      cityName:    cityName,
    );

    return (weather: weather, peakStart: peakStart, peakEnd: peakEnd, currentUV: currentUV);
  }

  /// Legacy method for backward compat
  static Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final result = await fetchWeatherAndPeak(
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
    );
    return result.weather;
  }
}