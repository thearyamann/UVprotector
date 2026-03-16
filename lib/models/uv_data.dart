class UVData {
  final double uvIndex;
  final String riskLevel;
  final double burnTimeMinutes;
  final String exposureAdvice;
  final String spfRecommendation;
  final int reapplyMinutes;
  final DateTime timestamp;
  final double? latitude;    
  final double? longitude;   

  UVData({
    required this.uvIndex,
    required this.riskLevel,
    required this.burnTimeMinutes,
    required this.exposureAdvice,
    required this.spfRecommendation,
    required this.reapplyMinutes,
    required this.timestamp,
    this.latitude,           
    this.longitude,
  });

  @override
  String toString() {
    return 'UVData(uvIndex: $uvIndex, risk: $riskLevel, '
        'burnTime: ${burnTimeMinutes.toStringAsFixed(1)} mins)';
  }
}
