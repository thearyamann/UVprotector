import 'package:flutter_test/flutter_test.dart';
import 'package:uv_index_app/engines/sun_exposure_engines.dart';

void main() {
  group('SunExposureEngine', () {
    group('calculateBurnTime', () {
      test('returns infinity for UV <= 0', () {
        expect(
          SunExposureEngine.calculateBurnTime(uvIndex: 0, skinTypeNumber: 1),
          double.infinity,
        );
        expect(
          SunExposureEngine.calculateBurnTime(uvIndex: -1, skinTypeNumber: 3),
          double.infinity,
        );
      });

      test('calculates burn time correctly for different skin types', () {
        final burnTimeType1 = SunExposureEngine.calculateBurnTime(
          uvIndex: 5,
          skinTypeNumber: 1,
        );
        expect(burnTimeType1, 67 / 5);

        final burnTimeType3 = SunExposureEngine.calculateBurnTime(
          uvIndex: 5,
          skinTypeNumber: 3,
        );
        expect(burnTimeType3, 200 / 5);
      });
    });

    group('getExposureAdvice', () {
      test('returns safe message for infinity burn time', () {
        expect(
          SunExposureEngine.getExposureAdvice(double.infinity),
          'No UV risk right now. Safe to go outside.',
        );
      });

      test('returns danger message for burn time < 15 minutes', () {
        expect(
          SunExposureEngine.getExposureAdvice(10),
          'Danger — burns in under 15 mins. Seek shade now.',
        );
        expect(
          SunExposureEngine.getExposureAdvice(14.9),
          'Danger — burns in under 15 mins. Seek shade now.',
        );
      });

      test('returns high risk message for burn time 15-30 minutes', () {
        expect(
          SunExposureEngine.getExposureAdvice(15),
          'High risk — limit exposure, apply SPF 30+.',
        );
        expect(
          SunExposureEngine.getExposureAdvice(29),
          'High risk — limit exposure, apply SPF 30+.',
        );
      });

      test('returns moderate risk message for burn time 30-60 minutes', () {
        expect(
          SunExposureEngine.getExposureAdvice(30),
          'Moderate risk — reapply sunscreen every 2 hours.',
        );
        expect(
          SunExposureEngine.getExposureAdvice(59),
          'Moderate risk — reapply sunscreen every 2 hours.',
        );
      });

      test('returns low risk message for burn time >= 60 minutes', () {
        expect(
          SunExposureEngine.getExposureAdvice(60),
          'Low risk — sunscreen still recommended.',
        );
        expect(
          SunExposureEngine.getExposureAdvice(120),
          'Low risk — sunscreen still recommended.',
        );
      });
    });
  });
}
