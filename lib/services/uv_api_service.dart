import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UVApiService {
  Future<double> fetchUVIndex(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://api.openuv.io/api/v1/uv?lat=$latitude&lng=$longitude',
    );

    late http.Response response;

    try {
      response = await http
          .get(url, headers: {'x-access-token': AppConfig.openUVApiKey})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timed out.'),
          );
    } catch (e) {
      throw Exception('Network error: $e');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['result'];
      if (result == null || result['uv'] == null) {
        throw Exception('Unexpected API response format.');
      }
      return (result['uv'] as num).toDouble().roundToDouble();
    } else if (response.statusCode == 401) {
      throw Exception('API key invalid. Check AppConfig.');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit hit. Try again later.');
    } else {
      throw Exception('API error: HTTP ${response.statusCode}');
    }
  }
}
