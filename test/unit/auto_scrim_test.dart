import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/auto_scrim.dart';

void main() {
  group('AutoScrim', () {
    test('bright palettes need a stronger scrim than dark ones', () {
      final bright = AutoScrim.opacityForPalette(const [Colors.white]);
      final dark = AutoScrim.opacityForPalette(const [Colors.black]);
      expect(bright, greaterThan(dark));
      expect(dark, AutoScrim.minOpacity);
    });

    test('opacity is clamped to the supported range', () {
      expect(
        AutoScrim.opacityForPalette(const [Colors.white, Colors.white]),
        lessThanOrEqualTo(AutoScrim.maxOpacity),
      );
    });

    test('adjust never weakens the user choice', () {
      expect(AutoScrim.adjust(0.8, const [Colors.black]), 0.8);
      expect(
        AutoScrim.adjust(0.1, const [Colors.white]),
        AutoScrim.opacityForPalette(const [Colors.white]),
      );
      expect(AutoScrim.adjust(0.3, null), 0.3);
      expect(AutoScrim.adjust(0.3, const []), 0.3);
    });
  });
}
