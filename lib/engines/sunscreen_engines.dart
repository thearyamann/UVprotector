class SunscreenEngine {
  /// AAD-aligned reapply intervals.
  /// SPF does NOT extend duration — per AAD: "reapply on the same schedule
  /// regardless of SPF level."
  static int getReapplyMinutes(double uvIndex) {
    if (uvIndex <= 0)  return 0;
    if (uvIndex <= 2)  return 0;   // Low — no timer needed
    if (uvIndex <= 7)  return 120;  // Moderate/High — 2 hours (AAD standard)
    if (uvIndex <= 10) return 90;   // Very High — 1.5 hours
    return 75;                      // Extreme — 1h 15m
  }

  /// Total sunscreen applications recommended per day.
  /// Accounts for skin type vulnerability.
  static int getTotalApplications(int skinType, double uvIndex) {
    if (uvIndex <= 2) return 0;

    // Fair skin (Type 1–2)
    if (skinType <= 2) {
      if (uvIndex >= 8) return 4;
      if (uvIndex >= 6) return 3;
      return 2;
    }

    // Medium / Olive skin (Type 3–4)
    if (skinType <= 4) {
      if (uvIndex >= 8) return 3;
      if (uvIndex >= 6) return 2;
      return 1;
    }

    // Brown / Dark skin (Type 5–6)
    if (uvIndex >= 8) return 2;
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