class SunscreenEngine {

  static int getReapplyMinutes(double uvIndex) {

    if (uvIndex < 3) return 180;
    if (uvIndex < 6) return 120;
    if (uvIndex < 8) return 90;

    return 60;

  }

}