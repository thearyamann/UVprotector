class SunscreenEngine {
  static int getReapplyMinutes(double uvIndex) {
    if (uvIndex < 3) return 180;
    if (uvIndex < 6) return 120;
    if (uvIndex < 8) return 90;
    return 60;
  }

  static String getSpfRecommendation(double uvIndex) {
    if (uvIndex <= 2) return 'SPF 15 sufficient.';
    if (uvIndex <= 5) return 'SPF 30 recommended.';
    if (uvIndex <= 7) return 'SPF 30–50 recommended.';
    if (uvIndex <= 10) return 'SPF 50 strongly recommended.';
    return 'SPF 50+ required. Seek shade when possible.';
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
