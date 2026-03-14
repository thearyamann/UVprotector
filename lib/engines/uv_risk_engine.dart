class UVRiskEngine {
  // Thresholds are defined once here — change them and the whole app updates
  static const Map<double, String> _thresholds = {
    2: 'Low',
    5: 'Moderate',
    7: 'High',
    10: 'Very High',
  };

  static String getRiskLevel(double uv) {
    for (final entry in _thresholds.entries) {
      if (uv <= entry.key) return entry.value;
    }
    return 'Extreme';
  }

  static String getRiskColor(double uv) {
    if (uv <= 2) return '#4CAF50'; // Green
    if (uv <= 5) return '#FFC107'; // Amber
    if (uv <= 7) return '#FF9800'; // Orange
    if (uv <= 10) return '#F44336'; // Red
    return '#9C27B0'; // Purple
  }
}
