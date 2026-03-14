class UVData {
  final double uvIndex;
  final String riskLevel;
  final double burnTimeMinutes;
  final String exposureAdvice;
  final String spfRecommendation;
  final int reapplyMinutes;
  final DateTime timestamp;

  UVData({
    required this.uvIndex,
    required this.riskLevel,
    required this.burnTimeMinutes,
    required this.exposureAdvice,
    required this.spfRecommendation,
    required this.reapplyMinutes,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'UVData(uvIndex: $uvIndex, risk: $riskLevel, '
        'burnTime: ${burnTimeMinutes.toStringAsFixed(1)} mins)';
  }
}
