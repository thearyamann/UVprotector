import 'package:flutter_test/flutter_test.dart';
import 'package:uv_index_app/engines/tanning_calculator.dart';
import 'package:uv_index_app/models/skin_type.dart';

void main() {
  group('TanningCalculator', () {
    group('calculateBurnTime', () {
      test('returns infinity for UV <= 0', () {
        expect(
          TanningCalculator.calculateBurnTime(
            uvIndex: 0,
            skinType: SkinType.type1,
          ),
          double.infinity,
        );
      });

      test('calculates burn time correctly', () {
        final burnTime = TanningCalculator.calculateBurnTime(
          uvIndex: 5,
          skinType: SkinType.type1,
        );
        expect(burnTime, SkinType.type1.baseBurnTime / 5);
      });

      test('handles different skin types', () {
        final burnTime1 = TanningCalculator.calculateBurnTime(
          uvIndex: 5,
          skinType: SkinType.type1,
        );
        final burnTime3 = TanningCalculator.calculateBurnTime(
          uvIndex: 5,
          skinType: SkinType.type3,
        );
        expect(burnTime1, isNot(burnTime3));
      });
    });

    group('fromTypeNumber', () {
      test('returns infinity for UV <= 0', () {
        expect(
          TanningCalculator.fromTypeNumber(uvIndex: 0, skinTypeNumber: 1),
          double.infinity,
        );
      });

      test('creates skin type from number and calculates burn time', () {
        final burnTime = TanningCalculator.fromTypeNumber(
          uvIndex: 5,
          skinTypeNumber: 3,
        );
        expect(burnTime, SkinType.type3.baseBurnTime / 5);
      });
    });
  });
}
