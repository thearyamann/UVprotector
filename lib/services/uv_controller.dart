import '../engines/uv_risk_engine.dart';
import '../engines/sun_exposure_engines.dart';
import '../engines/sunscreen_engines.dart';
import '../models/uv_data.dart';

class UVController {
  UVController();

  Future<UVData> getCurrentUVData({
    required double uvIndex,
    required double latitude,
    required double longitude,
    int skinTypeNumber = 1,
  }) async {
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
      latitude: latitude,
      longitude: longitude,
    );
  }
}
