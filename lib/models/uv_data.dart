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
  final String? peakStart;   // e.g. "12:00 PM"
  final String? peakEnd;     // e.g. "3:00 PM"

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
    this.peakStart,
    this.peakEnd,
  });

  UVData copyWith({
    double? uvIndex,
    String? riskLevel,
    double? burnTimeMinutes,
    String? exposureAdvice,
    String? spfRecommendation,
    int? reapplyMinutes,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? peakStart,
    String? peakEnd,
  }) {
    return UVData(
      uvIndex: uvIndex ?? this.uvIndex,
      riskLevel: riskLevel ?? this.riskLevel,
      burnTimeMinutes: burnTimeMinutes ?? this.burnTimeMinutes,
      exposureAdvice: exposureAdvice ?? this.exposureAdvice,
      spfRecommendation: spfRecommendation ?? this.spfRecommendation,
      reapplyMinutes: reapplyMinutes ?? this.reapplyMinutes,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      peakStart: peakStart ?? this.peakStart,
      peakEnd: peakEnd ?? this.peakEnd,
    );
  }

  @override
  String toString() {
    return 'UVData(uvIndex: $uvIndex, risk: $riskLevel, '
        'burnTime: ${burnTimeMinutes.toStringAsFixed(1)} mins)';
  }
}
