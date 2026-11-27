import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/card_fonts.dart';

void main() {
  group('CardFonts', () {
    test('only bundled families are exposed', () {
      expect(CardFonts.display, 'BigShouldersDisplay');
      expect(CardFonts.text, 'Inter');
      expect(CardFonts.serif, 'Lora');
      expect(CardFonts.mono, 'SpaceMono');
    });

    test('legacy family names resolve to a bundled family', () {
      expect(CardFonts.resolveFamily(null), CardFonts.text);
      expect(CardFonts.resolveFamily('Inter'), CardFonts.text);
      expect(CardFonts.resolveFamily('Lora'), CardFonts.serif);
      expect(CardFonts.resolveFamily('Space Mono'), CardFonts.mono);
      expect(CardFonts.resolveFamily('JetBrains Mono'), CardFonts.mono);
      expect(CardFonts.resolveFamily('BarlowCondensed'), CardFonts.display);
      expect(CardFonts.resolveFamily('unknown-family'), CardFonts.text);
    });

    test('former jetBrainsMono labels use the bundled text family', () {
      final style = CardFonts.jetBrainsMono(fontSize: 11);
      expect(style.fontFamily, CardFonts.text);
      expect(style.fontVariations, contains(FontVariation('opsz', 14.0)));
    });

    test('variable families carry an explicit wght axis', () {
      final hero = CardFonts.bigShouldersDisplay(
        fontSize: 100,
        fontWeight: FontWeight.w900,
      );
      expect(hero.fontFamily, CardFonts.display);
      expect(hero.fontVariations, isNotNull);
      expect(
        hero.fontVariations!.singleWhere((v) => v.axis == 'wght').value,
        900,
      );

      final body = CardFonts.inter(fontSize: 16, fontWeight: FontWeight.w700);
      expect(
        body.fontVariations!.singleWhere((v) => v.axis == 'wght').value,
        700,
      );
    });

    test('Inter drives its optical size axis from the effective font size', () {
      final style = CardFonts.inter(fontSize: 48);
      expect(
        style.fontVariations!.singleWhere((v) => v.axis == 'opsz').value,
        32,
      );
      final small = CardFonts.inter(fontSize: 10);
      expect(
        small.fontVariations!.singleWhere((v) => v.axis == 'opsz').value,
        14,
      );
    });

    test('textStyle base values are preserved when no override is given', () {
      const base = TextStyle(color: Color(0xFF123456), letterSpacing: 2);
      final style = CardFonts.getFont('Inter', textStyle: base, fontSize: 13);
      expect(style.color, const Color(0xFF123456));
      expect(style.letterSpacing, 2);
      expect(style.fontSize, 13);
      expect(style.fontFamily, CardFonts.text);
    });
  });
}
