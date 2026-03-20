class AppConfig {
  AppConfig._();

  static const int apiTimeoutSeconds = 10;
  static const int geocodingTimeoutSeconds = 5;

  static const int cacheRefreshIntervalMinutes = 30;

  static const int sunscreenTimerLowThresholdSeconds = 600;
  static const double uvEscalationThreshold = 0.5;
  static const double uvHighThreshold = 6.0;

  static const double indoorTimerMultiplier = 3.0;

  static const int nameMinLength = 1;
  static const int nameMaxLength = 50;

  static const int defaultReapplyMinutesLow = 0;
  static const int defaultReapplyMinutesModerate = 120;
  static const int defaultReapplyMinutesVeryHigh = 90;
  static const int defaultReapplyMinutesExtreme = 75;

  static const int defaultSpf = 30;
  static const int defaultSkinType = 3;
}
