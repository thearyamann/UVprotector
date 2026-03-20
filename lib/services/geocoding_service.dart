import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../core/logger.dart';

class GeocodingService {
  static Future<String> getCityName(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'UVProtectorApp/1.0'})
          .timeout(Duration(seconds: AppConfig.geocodingTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          return address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['county'] as String? ??
              'My Location';
        }
      }
    } catch (e, st) {
      AppLogger.logApiError('geocoding', null, e, st);
    }
    return 'My Location';
  }
}
