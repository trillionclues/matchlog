import 'package:flutter_test/flutter_test.dart';
import 'package:matchlog/features/diary/presentation/providers/heatmap_models.dart';

void main() {
  group('IntensityTierX.fromCount', () {
    test('0 maps to none', () {
      expect(IntensityTierX.fromCount(0), IntensityTier.none);
    });

    test('1 maps to low', () {
      expect(IntensityTierX.fromCount(1), IntensityTier.low);
    });

    test('2 maps to medium', () {
      expect(IntensityTierX.fromCount(2), IntensityTier.medium);
    });

    test('3 maps to high', () {
      expect(IntensityTierX.fromCount(3), IntensityTier.high);
    });

    test('4 maps to peak', () {
      expect(IntensityTierX.fromCount(4), IntensityTier.peak);
    });

    test('100 maps to peak', () {
      expect(IntensityTierX.fromCount(100), IntensityTier.peak);
    });
  });
}
