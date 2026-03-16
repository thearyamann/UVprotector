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

  static Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weathercode'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=auto&forecast_days=1',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather fetch failed: ${response.statusCode}');
    }

    final data    = jsonDecode(response.body);
    final current = data['current'];
    final daily   = data['daily'];

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      high:        (daily['temperature_2m_max'][0] as num).toDouble(),
      low:         (daily['temperature_2m_min'][0] as num).toDouble(),
      condition:   _conditionFromCode(current['weathercode'] as int),
      cityName:    cityName,
    );
  }
}