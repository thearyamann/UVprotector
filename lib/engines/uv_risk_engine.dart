class UVRiskEngine {

  static String getRiskLevel(double uv) {

    if (uv <= 2) {
      return "Low";
    }

    if (uv <= 5) {
      return "Moderate";
    }

    if (uv <= 7) {
      return "High";
    }

    if (uv <= 10) {
      return "Very High";
    }

    return "Extreme";
  }

}