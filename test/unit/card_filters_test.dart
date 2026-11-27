import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/card_filters.dart';
import 'package:oreamnos/domain/models/card_config.dart';

void main() {
  group('CardFilters', () {
    test('duotone produces a 4x5 colour matrix', () {
      expect(
        CardFilters.duotone(
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ).length,
        20,
      );
    });

    test('maps black to shadow and white to light', () {
      const shadow = Color(0xFF101820);
      const light = Color(0xFF0095F6);
      final m = CardFilters.duotone(shadow, light);

      // Applying the matrix to L=0 yields the offset (shadow); to L=1 the
      // offset plus the summed luminance coefficients (light).
      double out(int row) =>
          m[row * 5 + 4] + m[row * 5] + m[row * 5 + 1] + m[row * 5 + 2];
      expect(out(0), closeTo(light.r, 0.001));
      expect(out(1), closeTo(light.g, 0.001));
      expect(out(2), closeTo(light.b, 0.001));
      expect(m[4], closeTo(shadow.r, 0.001));
      expect(m[9], closeTo(shadow.g, 0.001));
      expect(m[14], closeTo(shadow.b, 0.001));
    });

    test('duotone is exposed as a photo filter option', () {
      expect(PhotoFilter.values, contains(PhotoFilter.duotone));
    });
  });
}
