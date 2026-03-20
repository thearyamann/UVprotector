import 'package:flutter_test/flutter_test.dart';
import 'package:uv_index_app/engines/uv_risk_engine.dart';

void main() {
  group('UVRiskEngine', () {
    group('getRiskLevel', () {
      test('returns Low for UV <= 2', () {
        expect(UVRiskEngine.getRiskLevel(0), 'Low');
        expect(UVRiskEngine.getRiskLevel(1), 'Low');
        expect(UVRiskEngine.getRiskLevel(2), 'Low');
      });

      test('returns Moderate for UV > 2 and <= 5', () {
        expect(UVRiskEngine.getRiskLevel(2.1), 'Moderate');
        expect(UVRiskEngine.getRiskLevel(3), 'Moderate');
        expect(UVRiskEngine.getRiskLevel(5), 'Moderate');
      });

      test('returns High for UV > 5 and <= 7', () {
        expect(UVRiskEngine.getRiskLevel(5.1), 'High');
        expect(UVRiskEngine.getRiskLevel(6), 'High');
        expect(UVRiskEngine.getRiskLevel(7), 'High');
      });

      test('returns Very High for UV > 7 and <= 10', () {
        expect(UVRiskEngine.getRiskLevel(7.1), 'Very High');
        expect(UVRiskEngine.getRiskLevel(8), 'Very High');
        expect(UVRiskEngine.getRiskLevel(10), 'Very High');
      });

      test('returns Extreme for UV > 10', () {
        expect(UVRiskEngine.getRiskLevel(10.1), 'Extreme');
        expect(UVRiskEngine.getRiskLevel(15), 'Extreme');
        expect(UVRiskEngine.getRiskLevel(100), 'Extreme');
      });
    });

    group('getRiskColor', () {
      test('returns green color for low UV', () {
        expect(UVRiskEngine.getRiskColor(0), '#4CAF50');
        expect(UVRiskEngine.getRiskColor(2), '#4CAF50');
      });

      test('returns yellow color for moderate UV', () {
        expect(UVRiskEngine.getRiskColor(3), '#FFC107');
        expect(UVRiskEngine.getRiskColor(5), '#FFC107');
      });

      test('returns orange color for high UV', () {
        expect(UVRiskEngine.getRiskColor(6), '#FF9800');
        expect(UVRiskEngine.getRiskColor(7), '#FF9800');
      });

      test('returns red color for very high UV', () {
        expect(UVRiskEngine.getRiskColor(8), '#F44336');
        expect(UVRiskEngine.getRiskColor(10), '#F44336');
      });

      test('returns purple color for extreme UV', () {
        expect(UVRiskEngine.getRiskColor(11), '#9C27B0');
        expect(UVRiskEngine.getRiskColor(20), '#9C27B0');
      });
    });
  });
}
