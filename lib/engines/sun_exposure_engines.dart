import '../models/skin_type.dart';

class SunExposureEngine {
  static double calculateBurnTime({
    required double uvIndex,
    required int skinTypeNumber,
  }) {
    if (uvIndex <= 0) return double.infinity;
    final skinType = SkinType.fromType(skinTypeNumber);
    return skinType.baseBurnTime / uvIndex;
  }

  static String getExposureAdvice(double burnTimeMinutes) {
    if (burnTimeMinutes == double.infinity) {
      return 'No UV risk right now. Safe to go outside.';
    }
    if (burnTimeMinutes < 15) {
      return 'Danger — burns in under 15 mins. Seek shade now.';
    }
    if (burnTimeMinutes < 30) {
      return 'High risk — limit exposure, apply SPF 30+.';
    }
    if (burnTimeMinutes < 60) {
      return 'Moderate risk — reapply sunscreen every 2 hours.';
    }
    return 'Low risk — sunscreen still recommended.';
  }
}
