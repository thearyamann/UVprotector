class TanningCalculator {

  static double calculateBurnTime({
    required double uvIndex,
    required int baseSkinTime,
  }) {

    if (uvIndex == 0) {
      return double.infinity;
    }

    return baseSkinTime / uvIndex;
  }

}