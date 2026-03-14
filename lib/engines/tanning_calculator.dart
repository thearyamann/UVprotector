import '../models/skin_type.dart';

class TanningCalculator {
  static double calculateBurnTime({
    required double uvIndex,
    required SkinType skinType,
  }) {
    if (uvIndex <= 0) return double.infinity;
    return skinType.baseBurnTime / uvIndex;
  }

  static double fromTypeNumber({
    required double uvIndex,
    required int skinTypeNumber,
  }) {
    final skinType = SkinType.fromType(skinTypeNumber);
    return calculateBurnTime(uvIndex: uvIndex, skinType: skinType);
  }
}
