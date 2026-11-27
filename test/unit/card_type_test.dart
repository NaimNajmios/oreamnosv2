import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';
import 'package:oreamnos/config/theme/card_type.dart';
import 'package:oreamnos/domain/models/card_config.dart';

void main() {
  group('CardType', () {
    test('only hero and display use the bundled display face', () {
      expect(CardType.hero.fontFamily, CardFonts.display);
      expect(CardType.display.fontFamily, CardFonts.display);
      expect(CardType.title.fontFamily, CardFonts.text);
      expect(CardType.body.fontFamily, CardFonts.text);
      expect(CardType.label.fontFamily, CardFonts.text);
    });

    test('tier sizes follow the five-level scale', () {
      expect(
        CardType.hero.fontSize! >= 96 && CardType.hero.fontSize! <= 120,
        isTrue,
      );
      expect(
        CardType.display.fontSize! >= 44 && CardType.display.fontSize! <= 56,
        isTrue,
      );
      expect(
        CardType.title.fontSize! >= 24 && CardType.title.fontSize! <= 28,
        isTrue,
      );
      expect(CardType.body.fontSize, 16);
      expect(
        CardType.label.fontSize! >= 12 && CardType.label.fontSize! <= 13,
        isTrue,
      );
    });

    test('score and stat tiers request tabular figures', () {
      expect(
        CardType.hero.fontFeatures,
        contains(FontFeature.tabularFigures()),
      );
      expect(
        CardType.display.fontFeatures,
        contains(FontFeature.tabularFigures()),
      );
    });

    test('forSize picks the closest tier', () {
      expect(CardType.forSize(100).fontFamily, CardFonts.display);
      expect(CardType.forSize(48).fontFamily, CardFonts.display);
      expect(CardType.forSize(26).fontFamily, CardFonts.text);
      expect(CardType.forSize(16).fontFamily, CardFonts.text);
      expect(CardType.forSize(11).fontFamily, CardFonts.text);
    });

    test('CardConfig routes large text to the hero face', () {
      final hero = const CardConfig().font(fontSize: 96);
      expect(hero.fontFamily, CardFonts.display);
      final body = const CardConfig().font(fontSize: 14);
      expect(body.fontFamily, CardFonts.text);
      expect(body.fontFeatures, contains(FontFeature.tabularFigures()));
    });

    test('CardConfig still honours a bundled user font at text sizes', () {
      final style = const CardConfig(primaryFontFamilyName: 'Lora')
          .font(fontSize: 20);
      expect(style.fontFamily, CardFonts.serif);
    });
  });
}
