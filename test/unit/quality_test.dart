import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_export_format.dart';
import 'package:oreamnos/domain/services/contrast_guard.dart';
import 'package:oreamnos/domain/services/font_preflight.dart';

void main() {
  group('ContrastGuard', () {
    test('white on near-black is readable', () {
      expect(
        ContrastGuard.ratio(Colors.white, CardThemeTokens.nearBlack),
        greaterThan(ContrastGuard.minimumTextContrast),
      );
      expect(
        ContrastGuard.isReadable(Colors.white, CardThemeTokens.nearBlack),
        isTrue,
      );
    });

    test('low contrast pairs are rejected', () {
      expect(
        ContrastGuard.isReadable(
          const Color(0xFF777777),
          const Color(0xFFFFFFFF),
        ),
        isFalse,
      );
    });
  });

  group('CardExportFormat', () {
    test('maps to file extensions', () {
      expect(CardExportFormat.png.extension, 'png');
      expect(CardExportFormat.jpeg.extension, 'jpg');
      expect(CardExportFormat.values.length, 2);
    });
  });

  group('FontPreflight', () {
    test('lists all bundled card font assets', () {
      expect(FontPreflight.assets, contains('assets/fonts/Inter-Variable.ttf'));
      expect(
        FontPreflight.assets,
        contains('assets/fonts/BigShouldersDisplay-Variable.ttf'),
      );
      expect(FontPreflight.assets.length, 9);
    });
  });
}

abstract final class CardThemeTokens {
  static const Color nearBlack = Color(0xFF0B0B0F);
}
