import 'package:uv_index_app/services/location_service.dart';
import 'package:uv_index_app/services/uv_api_service.dart';
import 'package:uv_index_app/engines/uv_risk_engine.dart';
import 'package:uv_index_app/models/uv_data.dart';
import 'package:uv_index_app/engines/sun_exposure_engines.dart';

class UVController {

  final LocationService locationService = LocationService();
  final UVApiService apiService = UVApiService();

  Future<UVData> getCurrentUVData() async {


    final position = await locationService.getCurrentLocation();

    final uvIndex = await apiService.fetchUVIndex(
      position.latitude,
      position.longitude,
    );

    final riskLevel = UVRiskEngine.getRiskLevel(uvIndex);

    // Calculate burn time based on UV index and skin type.
    final burnTime = SunExposureEngine.calculateBurnTime(
      uvIndex: uvIndex,
      skinType: 3, // example skin type value
    );

    final uvData = UVData(
      uvIndex: uvIndex,
      riskLevel: riskLevel,
      burnTimeMinutes: burnTime,
      timestamp: DateTime.now(),
    );
    return uvData;

  }

}