import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../core/logger.dart';

class WeatherService {
  static String _conditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Showers';
    return 'Stormy';
  }

  static String _formatHour12(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ap = hour < 12 ? 'AM' : 'PM';
    return '$h:00 $ap';
  }

  static String _formatLocalHour(DateTime time) =>
      _formatHour12(time.toLocal().hour);

  static String _conditionFromMetSymbol(String symbolCode) {
    final normalized = symbolCode.toLowerCase();
    if (normalized.contains('clearsky')) return 'Clear';
    if (normalized.contains('fair')) return 'Partly cloudy';
    if (normalized.contains('partlycloudy')) return 'Partly cloudy';
    if (normalized.contains('cloudy')) return 'Cloudy';
    if (normalized.contains('fog')) return 'Foggy';
    if (normalized.contains('rain')) return 'Rainy';
    if (normalized.contains('snow')) return 'Snowy';
    if (normalized.contains('sleet')) return 'Showers';
    if (normalized.contains('thunder')) return 'Stormy';
    return 'Clear';
  }

  static Future<
    ({WeatherData weather, String peakStart, String peakEnd, double currentUV})
  >
  fetchWeatherAndPeak({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    try {
      print('[UV] WeatherService: trying Open-Meteo UV Index API...');
      final result = await _fetchUVIndexFromAPI(
        latitude: latitude,
        longitude: longitude,
        cityName: cityName,
      );
      print('[UV] WeatherService: UV Index API SUCCESS');
      return result;
    } catch (e, st) {
      print('[UV] WeatherService: UV Index API FAILED – $e');
      AppLogger.logServiceError(
        'WeatherService',
        'fetchWeatherAndPeak.uvIndex',
        e,
        st,
      );
    }

    try {
      print('[UV] WeatherService: trying MET Norway API...');
      final result = await _fetchMetNoWeatherAndPeak(
        latitude: latitude,
        longitude: longitude,
        cityName: cityName,
      );
      print('[UV] WeatherService: MET Norway SUCCESS');
      return result;
    } catch (e, st) {
      print('[UV] WeatherService: MET Norway FAILED – $e');
      AppLogger.logServiceError(
        'WeatherService',
        'fetchWeatherAndPeak.metNo',
        e,
        st,
      );
    }

    try {
      print('[UV] WeatherService: trying Open-Meteo detailed API...');
      final result = await _fetchDetailedWeatherAndPeak(
        latitude: latitude,
        longitude: longitude,
        cityName: cityName,
      );
      print('[UV] WeatherService: Open-Meteo detailed SUCCESS');
      return result;
    } catch (e, st) {
      print('[UV] WeatherService: Open-Meteo detailed FAILED – $e');
      AppLogger.logServiceError(
        'WeatherService',
        'fetchWeatherAndPeak.detailed',
        e,
        st,
      );

      try {
        print('[UV] WeatherService: trying Open-Meteo current-only API...');
        final result = await _fetchCurrentOnlyWeather(
          latitude: latitude,
          longitude: longitude,
          cityName: cityName,
        );
        print('[UV] WeatherService: Open-Meteo current-only SUCCESS');
        return result;
      } catch (fallbackError, fallbackSt) {
        print(
          '[UV] WeatherService: Open-Meteo current-only FAILED – $fallbackError',
        );
        AppLogger.logServiceError(
          'WeatherService',
          'fetchWeatherAndPeak.fallback',
          fallbackError,
          fallbackSt,
        );
        throw WeatherException(
          'Failed to fetch weather data',
          cause: fallbackError,
        );
      }
    }
  }

  static Future<
    ({WeatherData weather, String peakStart, String peakEnd, double currentUV})
  >
  _fetchUVIndexFromAPI({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final now = DateTime.now();

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&hourly=uv_index'
      '&current=uv_index'
      '&timezone=auto'
      '&forecast_days=2',
    );

    final response = await _getWithRetry(
      url,
      timeoutSeconds: 20,
      maxAttempts: 2,
    );

    if (response.statusCode != 200) {
      throw WeatherException(
        'UV Index API failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
        cause: response.body,
      );
    }

    final data = jsonDecode(response.body);
    final current = data['current'] as Map<String, dynamic>?;
    final hourly = data['hourly'] as Map<String, dynamic>?;

    if (hourly == null) {
      throw const WeatherException('UV Index response missing hourly data');
    }

    final currentUV = (current?['uv_index'] as num?)?.toDouble() ?? 0.0;
    final times = (hourly['time'] as List).cast<String>();
    final uvList = (hourly['uv_index'] as List);

    double maxUV = 0.0;
    int? peakStartHour;
    int? peakEndHour;

    for (int i = 0; i < times.length; i++) {
      final time = DateTime.parse(times[i]);
      if (time.day != now.day) continue;

      final uv = (uvList[i] as num?)?.toDouble() ?? 0.0;

      if (uv > maxUV) maxUV = uv;

      if (uv > maxUV * 0.8 && uv > 0.5) {
        peakStartHour ??= time.hour;
        peakEndHour = time.hour;
      }
    }

    final weatherResult = await _fetchWeatherOnly(
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
    );

    return (
      weather: weatherResult,
      peakStart: peakStartHour != null
          ? _formatHour12(peakStartHour)
          : '12:00 PM',
      peakEnd: peakEndHour != null ? _formatHour12(peakEndHour + 1) : '3:00 PM',
      currentUV: currentUV,
    );
  }

  static _fetchSatelliteRadiationUV({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final now = DateTime.now();
    final startDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day - 1).toString().padLeft(2, '0')}';
    final endDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final url = Uri.parse(
      'https://satellite-api.open-meteo.com/v1/archive'
      '?latitude=$latitude&longitude=$longitude'
      '&start_date=$startDate&end_date=$endDate'
      '&hourly=shortwave_radiation,direct_radiation,diffuse_radiation'
      '&models=satellite_radiation_seamless'
      '&timezone=auto',
    );

    final response = await _getWithRetry(
      url,
      timeoutSeconds: 20,
      maxAttempts: 2,
    );

    if (response.statusCode != 200) {
      throw WeatherException(
        'Satellite Radiation API failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
        cause: response.body,
      );
    }

    final data = jsonDecode(response.body);
    final hourly = data['hourly'] as Map<String, dynamic>?;

    if (hourly == null) {
      throw const WeatherException(
        'Satellite Radiation response missing hourly data',
      );
    }

    final times = (hourly['time'] as List).cast<String>();
    final shortwaveList = (hourly['shortwave_radiation'] as List);
    final directList = (hourly['direct_radiation'] as List);
    final diffuseList = (hourly['diffuse_radiation'] as List);

    double currentUV = 0.0;
    double maxUV = 0.0;
    int? peakStartHour;
    int? peakEndHour;

    for (int i = 0; i < times.length; i++) {
      final time = DateTime.parse(times[i]);
      if (time.day != now.day) continue;

      final shortwave = (shortwaveList[i] as num?)?.toDouble() ?? 0.0;
      final direct = (directList[i] as num?)?.toDouble() ?? 0.0;
      final diffuse = (diffuseList[i] as num?)?.toDouble() ?? 0.0;

      final uv = _calculateUVIndex(shortwave, direct, diffuse, latitude, time);

      if (time.hour == now.hour ||
          (time.hour == now.hour - 1 && currentUV == 0)) {
        currentUV = uv;
      }

      if (uv > maxUV) maxUV = uv;

      if (uv > maxUV * 0.8 && uv > 0.5) {
        peakStartHour ??= time.hour;
        peakEndHour = time.hour;
      }
    }

    if (currentUV == 0 && maxUV > 0) {
      currentUV = maxUV * 0.7;
    }

    final weatherResult = await _fetchWeatherOnly(
      latitude: latitude,
      longitude: longitude,
      cityName: cityName,
    );

    return (
      weather: weatherResult,
      peakStart: peakStartHour != null
          ? _formatHour12(peakStartHour)
          : '12:00 PM',
      peakEnd: peakEndHour != null ? _formatHour12(peakEndHour + 1) : '3:00 PM',
      currentUV: currentUV,
    );
  }

  static double _calculateUVIndex(
    double shortwaveRadiation,
    double directRadiation,
    double diffuseRadiation,
    double latitude,
    DateTime time,
  ) {
    if (shortwaveRadiation <= 0) return 0.0;

    final zenithAngle = _calculateSolarZenithAngle(latitude, time);
    if (zenithAngle > 85) return 0.0;

    final cosZenith = math.cos(zenithAngle);
    if (cosZenith <= 0) return 0.0;

    final extraterrestrialUV = shortwaveRadiation * 0.014;

    final cloudAttenuation = _estimateCloudAttenuation(
      shortwaveRadiation,
      directRadiation,
      diffuseRadiation,
    );

    final uvIndex = extraterrestrialUV * cosZenith * cloudAttenuation;

    return uvIndex.clamp(0.0, 15.0);
  }

  static double _calculateSolarZenithAngle(double latitude, DateTime time) {
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays + 1;
    final declination =
        23.45 * math.sin((360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0);
    final hourAngle = (time.hour + time.minute / 60.0 - 12.0) * 15.0;

    final latRad = latitude * math.pi / 180.0;
    final decRad = declination * math.pi / 180.0;
    final hourRad = hourAngle * math.pi / 180.0;

    final cosZenith =
        math.sin(latRad) * math.sin(decRad) +
        math.cos(latRad) * math.cos(decRad) * math.cos(hourRad);

    return math.acos(cosZenith.clamp(-1.0, 1.0));
  }

  static double _estimateCloudAttenuation(
    double shortwave,
    double direct,
    double diffuse,
  ) {
    if (shortwave <= 0) return 1.0;

    final clearnessIndex = shortwave / 1000.0;

    double attenuation;
    if (clearnessIndex > 0.7) {
      attenuation = 1.0;
    } else if (clearnessIndex > 0.5) {
      attenuation = 0.85;
    } else if (clearnessIndex > 0.3) {
      attenuation = 0.65;
    } else {
      attenuation = 0.4;
    }

    if (diffuse > 0 && shortwave > 0) {
      final diffuseFraction = diffuse / shortwave;
      if (diffuseFraction > 0.8) {
        attenuation *= 0.5;
      } else if (diffuseFraction > 0.6) {
        attenuation *= 0.7;
      } else if (diffuseFraction > 0.4) {
        attenuation *= 0.85;
      }
    }

    return attenuation.clamp(0.2, 1.0);
  }

  static Future<WeatherData> _fetchWeatherOnly({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,weather_code'
        '&daily=temperature_2m_max,temperature_2m_min'
        '&timezone=auto&forecast_days=1',
      );

      final response = await _getWithRetry(
        url,
        timeoutSeconds: 15,
        maxAttempts: 2,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final daily = data['daily'];

        return WeatherData(
          temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
          high: (daily['temperature_2m_max'][0] as num).toDouble(),
          low: (daily['temperature_2m_min'][0] as num).toDouble(),
          condition: _conditionFromCode(
            (current['weather_code'] as num?)?.toInt() ?? 0,
          ),
          cityName: cityName,
        );
      }
    } catch (_) {}

    return WeatherData(
      temperature: 0.0,
      high: 0.0,
      low: 0.0,
      condition: 'Clear',
      cityName: cityName,
    );
  }

  static Future<
    ({WeatherData weather, String peakStart, String peakEnd, double currentUV})
  >
  _fetchMetNoWeatherAndPeak({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final url = Uri.parse(
      'https://api.met.no/weatherapi/locationforecast/2.0/complete'
      '?lat=$latitude&lon=$longitude',
    );

    final response = await _getWithRetry(
      url,
      timeoutSeconds: 15,
      maxAttempts: 2,
    );

    if (response.statusCode != 200) {
      throw WeatherException(
        'MET Norway fetch failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
        cause: response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final properties = data['properties'] as Map<String, dynamic>?;
    final timeseries = properties?['timeseries'] as List<dynamic>?;
    if (timeseries == null || timeseries.isEmpty) {
      throw const WeatherException('MET Norway response missing timeseries');
    }

    final firstEntry = timeseries.first as Map<String, dynamic>;
    final firstData = firstEntry['data'] as Map<String, dynamic>;
    final firstInstant = firstData['instant'] as Map<String, dynamic>;
    final firstDetails = firstInstant['details'] as Map<String, dynamic>;

    final now = DateTime.now();
    final relevantEntries = <Map<String, dynamic>>[];
    for (final raw in timeseries.take(24)) {
      final entry = raw as Map<String, dynamic>;
      final time = DateTime.parse(entry['time'] as String).toLocal();
      if (time.isAfter(now.subtract(const Duration(hours: 1)))) {
        relevantEntries.add(entry);
      }
    }
    if (relevantEntries.isEmpty) {
      relevantEntries.add(firstEntry);
    }

    double currentUV =
        (firstDetails['ultraviolet_index_clear_sky'] as num?)?.toDouble() ??
        0.0;
    double high = (firstDetails['air_temperature'] as num?)?.toDouble() ?? 0.0;
    double low = high;
    double maxUV = currentUV;
    DateTime? peakStartTime;
    DateTime? peakEndTime;

    for (final entry in relevantEntries) {
      final time = DateTime.parse(entry['time'] as String);
      final details =
          ((entry['data'] as Map<String, dynamic>)['instant']
                  as Map<String, dynamic>)['details']
              as Map<String, dynamic>;
      final temperature =
          (details['air_temperature'] as num?)?.toDouble() ?? high;
      final uv =
          (details['ultraviolet_index_clear_sky'] as num?)?.toDouble() ?? 0.0;

      if (temperature > high) high = temperature;
      if (temperature < low) low = temperature;
      if (uv > maxUV) maxUV = uv;

      if (uv > 0) {
        peakStartTime ??= time;
        peakEndTime = time;
      }
    }

    if (maxUV > 0) {
      final threshold = maxUV * 0.8;
      peakStartTime = null;
      peakEndTime = null;
      for (final entry in relevantEntries) {
        final time = DateTime.parse(entry['time'] as String);
        final details =
            ((entry['data'] as Map<String, dynamic>)['instant']
                    as Map<String, dynamic>)['details']
                as Map<String, dynamic>;
        final uv =
            (details['ultraviolet_index_clear_sky'] as num?)?.toDouble() ?? 0.0;
        if (uv >= threshold && uv > 0) {
          peakStartTime ??= time;
          peakEndTime = time;
        }
      }
    }

    final summary =
        (firstData['next_1_hours'] as Map<String, dynamic>?)?['summary']
            as Map<String, dynamic>?;
    final symbolCode =
        summary?['symbol_code'] as String? ??
        (((firstData['next_6_hours'] as Map<String, dynamic>?)?['summary']
                as Map<String, dynamic>?)?['symbol_code']
            as String?) ??
        'clearsky_day';

    final weather = WeatherData(
      temperature: (firstDetails['air_temperature'] as num?)?.toDouble() ?? 0.0,
      high: high,
      low: low,
      condition: _conditionFromMetSymbol(symbolCode),
      cityName: cityName,
    );

    return (
      weather: weather,
      peakStart: peakStartTime != null
          ? _formatLocalHour(peakStartTime)
          : '12:00 PM',
      peakEnd: peakEndTime != null
          ? _formatLocalHour(peakEndTime.add(const Duration(hours: 1)))
          : '3:00 PM',
      currentUV: currentUV,
    );
  }

  static Future<
    ({WeatherData weather, String peakStart, String peakEnd, double currentUV})
  >
  _fetchDetailedWeatherAndPeak({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weather_code,uv_index'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&hourly=uv_index'
      '&timezone=auto&forecast_days=1',
    );

    final response = await _getWithRetry(
      url,
      timeoutSeconds: 15,
      maxAttempts: 2,
    );

    if (response.statusCode != 200) {
      throw WeatherException(
        'Weather fetch failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
        cause: response.body,
      );
    }

    final data = jsonDecode(response.body);
    final current = data['current'];
    final daily = data['daily'];
    final currentUV = (current['uv_index'] as num?)?.toDouble() ?? 0.0;

    String peakStart = '12:00 PM';
    String peakEnd = '3:00 PM';

    final hourly = data['hourly'];
    if (hourly != null && hourly['uv_index'] != null) {
      final uvList = (hourly['uv_index'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      if (uvList.isNotEmpty) {
        double maxUV = 0;
        for (final v in uvList) {
          if (v > maxUV) maxUV = v;
        }

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
          peakEnd = _formatHour12(endHour + 1);
        }
      }
    }

    final weather = WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      high: (daily['temperature_2m_max'][0] as num).toDouble(),
      low: (daily['temperature_2m_min'][0] as num).toDouble(),
      condition: _conditionFromCode(
        (current['weather_code'] as num?)?.toInt() ??
            (current['weathercode'] as num?)?.toInt() ??
            0,
      ),
      cityName: cityName,
    );

    return (
      weather: weather,
      peakStart: peakStart,
      peakEnd: peakEnd,
      currentUV: currentUV,
    );
  }

  static Future<
    ({WeatherData weather, String peakStart, String peakEnd, double currentUV})
  >
  _fetchCurrentOnlyWeather({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weather_code,uv_index'
      '&forecast_days=1',
    );

    final response = await _getWithRetry(
      url,
      timeoutSeconds: 15,
      maxAttempts: 2,
    );

    if (response.statusCode != 200) {
      throw WeatherException(
        'Fallback weather fetch failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
        cause: response.body,
      );
    }

    final data = jsonDecode(response.body);
    final current = data['current'];
    final temperature = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final currentUV = (current['uv_index'] as num?)?.toDouble() ?? 0.0;
    final weatherCode =
        (current['weather_code'] as num?)?.toInt() ??
        (current['weathercode'] as num?)?.toInt() ??
        0;

    final weather = WeatherData(
      temperature: temperature,
      high: temperature,
      low: temperature,
      condition: _conditionFromCode(weatherCode),
      cityName: cityName,
    );

    return (
      weather: weather,
      peakStart: '12:00 PM',
      peakEnd: '3:00 PM',
      currentUV: currentUV,
    );
  }

  static Future<http.Response> _getWithRetry(
    Uri url, {
    required int timeoutSeconds,
    int maxAttempts = 2,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await http
            .get(
              url,
              headers: const {
                'User-Agent': 'UVProtectorApp/1.0',
                'Accept': 'application/json',
              },
            )
            .timeout(Duration(seconds: timeoutSeconds));
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
        }
      }
    }

    throw lastError ?? const WeatherException('Weather request failed');
  }

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

class WeatherException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const WeatherException(this.message, {this.statusCode, this.cause});

  @override
  String toString() {
    final codePart = statusCode != null ? ' [$statusCode]' : '';
    final causePart = cause != null ? ' | Cause: $cause' : '';
    return 'WeatherException$codePart: $message$causePart';
  }
}
