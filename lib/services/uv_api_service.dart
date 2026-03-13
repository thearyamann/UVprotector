import 'dart:convert';
import 'package:http/http.dart' as http;

class UVApiService {
  Future<double> fetchUVIndex(double latitude, double longitude) async {
    final url = Uri.parse(
      "https://api.openuv.io/api/v1/uv?lat=$latitude&lng=$longitude",
    );

    final response = await http.get(
      url,
      headers: {"x-access-token": "openuv-hl753rmmosurxz-io"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      double uv = data["result"]["uv"];
      return uv.roundToDouble();
    } else {
      throw Exception("Failed to load UV data");
    }
  }
}
