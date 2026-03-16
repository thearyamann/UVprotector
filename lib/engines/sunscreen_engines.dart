class SunscreenEngine {
  static int getReapplyMinutes(double uvIndex, int spf) {
    if (uvIndex <= 0) return 0;
    int base;
    if (uvIndex < 3)       base = 180;
    else if (uvIndex < 6)  base = 120;
    else if (uvIndex < 8)  base = 90;
    else                   base = 60;

    double multiplier;
    if (spf >= 50)      multiplier = 1.6;
    else if (spf >= 30) multiplier = 1.3;
    else                multiplier = 1.0;

    return (base * multiplier).round();
  }

  static int getTotalApplications(int skinType, double uvIndex) {
    if (uvIndex <= 2) return 0;
    if (skinType <= 2) {
      if (uvIndex >= 8) return 4;
      if (uvIndex >= 6) return 3;
      return 2;
    }
    if (skinType <= 4) {
      if (uvIndex >= 8) return 3;
      if (uvIndex >= 6) return 2;
      return 1;
    }
    return 1;
  }

  static String getSpfRecommendation(double uvIndex) {
    if (uvIndex <= 0)  return 'No sunscreen needed.';
    if (uvIndex <= 2)  return 'SPF 15 sufficient.';
    if (uvIndex <= 5)  return 'SPF 30 recommended.';
    if (uvIndex <= 7)  return 'SPF 30–50 recommended.';
    if (uvIndex <= 10) return 'SPF 50 strongly recommended.';
    return 'SPF 50+ required. Seek shade.';
  }

  static double calculateProtectionTime({
    required double burnTimeMinutes,
    required int spf,
  }) {
    if (burnTimeMinutes == double.infinity) return double.infinity;
    if (spf <= 0) return burnTimeMinutes;
    return (burnTimeMinutes * spf).clamp(0, 120);
  }
}