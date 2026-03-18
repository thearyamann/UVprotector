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
    // ⚠️ TEMP: Hardcoded UV for testing
    const double testingUV = 6.0; 
    
    final riskLevel = UVRiskEngine.getRiskLevel(testingUV);
    final burnTime = SunExposureEngine.calculateBurnTime(
      uvIndex: testingUV,
      skinTypeNumber: skinTypeNumber,
    );
    final advice = SunExposureEngine.getExposureAdvice(burnTime);
    final spf = SunscreenEngine.getSpfRecommendation(testingUV);
    final reapply = SunscreenEngine.getReapplyMinutes(testingUV);

    return UVData(
      uvIndex: testingUV,
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
