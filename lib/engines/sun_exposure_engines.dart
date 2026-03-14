class SunExposureEngine {
  static int calculateBurnTime({
    required double uvIndex,
    required int skinType,
  }) {
    final Map<int, int> baseBurnTimes = {
      1: 10,
      2: 15,
      3: 20,
      4: 25,
      5: 35,
      6: 45,
    };

    int baseTime = baseBurnTimes[skinType] ?? 20;

    if (uvIndex <= 0) {
      return 999;
    }

    double burnTime = (baseTime * 10) / uvIndex;

    return burnTime.round();
  }
}
