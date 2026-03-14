class UVRiskEngine {

  static final Map<double, String> _thresholds = {
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
    if (uv <= 2) return '#4CAF50'; 
    if (uv <= 5) return '#FFC107'; 
    if (uv <= 7) return '#FF9800'; 
    if (uv <= 10) return '#F44336';
    return '#9C27B0'; 
  }
}
