import 'package:flutter_test/flutter_test.dart';
import 'package:uv_index_app/engines/sunscreen_engines.dart';

void main() {
  group('SunscreenEngine', () {
    group('getReapplyMinutes', () {
      test('returns 0 for UV <= 0', () {
        expect(SunscreenEngine.getReapplyMinutes(-1), 0);
        expect(SunscreenEngine.getReapplyMinutes(0), 0);
      });

      test('returns 0 for low UV <= 2', () {
        expect(SunscreenEngine.getReapplyMinutes(1), 0);
        expect(SunscreenEngine.getReapplyMinutes(2), 0);
      });

      test('returns 120 minutes for moderate/high UV <= 7', () {
        expect(SunscreenEngine.getReapplyMinutes(3), 120);
        expect(SunscreenEngine.getReapplyMinutes(5), 120);
        expect(SunscreenEngine.getReapplyMinutes(7), 120);
      });

      test('returns 90 minutes for very high UV <= 10', () {
        expect(SunscreenEngine.getReapplyMinutes(8), 90);
        expect(SunscreenEngine.getReapplyMinutes(10), 90);
      });

      test('returns 75 minutes for extreme UV > 10', () {
        expect(SunscreenEngine.getReapplyMinutes(11), 75);
        expect(SunscreenEngine.getReapplyMinutes(15), 75);
      });
    });

    group('getTotalApplications', () {
      test('returns 0 for low UV <= 2', () {
        expect(SunscreenEngine.getTotalApplications(1, 0), 0);
        expect(SunscreenEngine.getTotalApplications(3, 2), 0);
        expect(SunscreenEngine.getTotalApplications(6, 1), 0);
      });

      group('for fair skin (Type 1-2)', () {
        test('returns 2 applications for UV < 6', () {
          expect(SunscreenEngine.getTotalApplications(1, 3), 2);
          expect(SunscreenEngine.getTotalApplications(2, 5), 2);
        });

        test('returns 3 applications for UV >= 6 and < 8', () {
          expect(SunscreenEngine.getTotalApplications(1, 6), 3);
          expect(SunscreenEngine.getTotalApplications(2, 7), 3);
        });

        test('returns 4 applications for UV >= 8', () {
          expect(SunscreenEngine.getTotalApplications(1, 8), 4);
          expect(SunscreenEngine.getTotalApplications(2, 10), 4);
        });
      });

      group('for medium/olive skin (Type 3-4)', () {
        test('returns 1 application for UV < 6', () {
          expect(SunscreenEngine.getTotalApplications(3, 3), 1);
          expect(SunscreenEngine.getTotalApplications(4, 5), 1);
        });

        test('returns 2 applications for UV >= 6 and < 8', () {
          expect(SunscreenEngine.getTotalApplications(3, 6), 2);
          expect(SunscreenEngine.getTotalApplications(4, 7), 2);
        });

        test('returns 3 applications for UV >= 8', () {
          expect(SunscreenEngine.getTotalApplications(3, 8), 3);
          expect(SunscreenEngine.getTotalApplications(4, 10), 3);
        });
      });

      group('for brown/dark skin (Type 5-6)', () {
        test('returns 1 application for UV < 8', () {
          expect(SunscreenEngine.getTotalApplications(5, 3), 1);
          expect(SunscreenEngine.getTotalApplications(6, 7), 1);
        });

        test('returns 2 applications for UV >= 8', () {
          expect(SunscreenEngine.getTotalApplications(5, 8), 2);
          expect(SunscreenEngine.getTotalApplications(6, 10), 2);
        });
      });
    });

    group('getSpfRecommendation', () {
      test('returns no sunscreen needed for UV <= 0', () {
        expect(SunscreenEngine.getSpfRecommendation(0), 'No sunscreen needed.');
        expect(
          SunscreenEngine.getSpfRecommendation(-1),
          'No sunscreen needed.',
        );
      });

      test('returns SPF 15 sufficient for UV <= 2', () {
        expect(SunscreenEngine.getSpfRecommendation(1), 'SPF 15 sufficient.');
        expect(SunscreenEngine.getSpfRecommendation(2), 'SPF 15 sufficient.');
      });

      test('returns SPF 30 recommended for UV <= 5', () {
        expect(SunscreenEngine.getSpfRecommendation(3), 'SPF 30 recommended.');
        expect(SunscreenEngine.getSpfRecommendation(5), 'SPF 30 recommended.');
      });

      test('returns SPF 30-50 recommended for UV <= 7', () {
        expect(
          SunscreenEngine.getSpfRecommendation(6),
          'SPF 30–50 recommended.',
        );
        expect(
          SunscreenEngine.getSpfRecommendation(7),
          'SPF 30–50 recommended.',
        );
      });

      test('returns SPF 50 strongly recommended for UV <= 10', () {
        expect(
          SunscreenEngine.getSpfRecommendation(8),
          'SPF 50 strongly recommended.',
        );
        expect(
          SunscreenEngine.getSpfRecommendation(10),
          'SPF 50 strongly recommended.',
        );
      });

      test('returns SPF 50+ required for UV > 10', () {
        expect(
          SunscreenEngine.getSpfRecommendation(11),
          'SPF 50+ required. Seek shade.',
        );
        expect(
          SunscreenEngine.getSpfRecommendation(15),
          'SPF 50+ required. Seek shade.',
        );
      });
    });

    group('calculateProtectionTime', () {
      test('returns infinity for infinity burn time', () {
        expect(
          SunscreenEngine.calculateProtectionTime(
            burnTimeMinutes: double.infinity,
            spf: 30,
          ),
          double.infinity,
        );
      });

      test('returns burn time for invalid SPF <= 0', () {
        expect(
          SunscreenEngine.calculateProtectionTime(burnTimeMinutes: 30, spf: 0),
          30,
        );
        expect(
          SunscreenEngine.calculateProtectionTime(burnTimeMinutes: 30, spf: -1),
          30,
        );
      });

      test('calculates protection time correctly', () {
        expect(
          SunscreenEngine.calculateProtectionTime(burnTimeMinutes: 3, spf: 30),
          90,
        );
      });

      test('clamps protection time to max 120 minutes', () {
        expect(
          SunscreenEngine.calculateProtectionTime(burnTimeMinutes: 10, spf: 30),
          120,
        );
        expect(
          SunscreenEngine.calculateProtectionTime(burnTimeMinutes: 5, spf: 50),
          120,
        );
      });
    });
  });
}
