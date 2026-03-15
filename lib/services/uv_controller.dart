import 'location_service.dart';
import 'uv_api_service.dart';
import '../engines/uv_risk_engine.dart';
import '../engines/sun_exposure_engines.dart';
import '../engines/sunscreen_engines.dart';
import '../models/uv_data.dart';

class UVController {
  final LocationService _locationService;
  final UVApiService _apiService;

  UVController({LocationService? locationService, UVApiService? apiService})
    : _locationService = locationService ?? LocationService(),
      _apiService = apiService ?? UVApiService();

  Future<UVData> getCurrentUVData({int skinTypeNumber = 3}) async {
    final position = await _locationService.getCurrentLocation();
    print('📍 Fetching UV for: ${position.latitude}, ${position.longitude}');

    final uvIndex = await _apiService.fetchUVIndex(
      position.latitude,
      position.longitude,
    );

    // All values computed dynamically from live uvIndex + skinType
    final riskLevel = UVRiskEngine.getRiskLevel(uvIndex);
    final burnTime = SunExposureEngine.calculateBurnTime(
      uvIndex: uvIndex,
      skinTypeNumber: skinTypeNumber,
    );
    final advice = SunExposureEngine.getExposureAdvice(burnTime);
    final spf = SunscreenEngine.getSpfRecommendation(uvIndex);
    final reapply = SunscreenEngine.getReapplyMinutes(uvIndex);

    return UVData(
      uvIndex: uvIndex,
      riskLevel: riskLevel,
      burnTimeMinutes: burnTime,
      exposureAdvice: advice,
      spfRecommendation: spf,
      reapplyMinutes: reapply,
      timestamp: DateTime.now(),
    );
  }
}
