import 'package:flutter/material.dart' hide CardTheme;
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/card_scale.dart';
import 'package:oreamnos/config/theme/card_theme.dart';
import 'package:oreamnos/domain/models/card_config.dart';

void main() {
  group('CardScale', () {
    test('ratio scale matches the legacy Magic Resize factors', () {
      expect(CardScale.ratioScale(ExportSize.square), 1.0);
      expect(CardScale.ratioScale(ExportSize.portrait), 1.0);
      expect(CardScale.ratioScale(ExportSize.photo34), 1.0);
      expect(CardScale.ratioScale(ExportSize.story), 1.05);
      expect(CardScale.ratioScale(ExportSize.wide), 0.88);
    });

    test('logical canvas keeps the 380-unit design width', () {
      expect(CardScale.logicalSize(ExportSize.square).width, 380);
      expect(
        CardScale.logicalSize(ExportSize.portrait).height,
        closeTo(475, 0.01),
      );
      expect(
        CardScale.logicalSize(ExportSize.wide).height,
        closeTo(213.75, 0.01),
      );
    });

    test('font scales by ratio and clamps the user scale', () {
      expect(
        CardScale.font(48, size: ExportSize.story, userScale: 1.0),
        closeTo(50.4, 0.001),
      );
      expect(
        CardScale.font(48, size: ExportSize.wide, userScale: 5),
        closeTo(48 * 0.88 * 2.5, 0.001),
      );
      expect(
        CardScale.font(48, size: ExportSize.square, userScale: 0.1),
        closeTo(48 * 0.5, 0.001),
      );
    });

    test('CardConfig delegates its ratio scale to CardScale', () {
      expect(
        const CardConfig(exportSize: ExportSize.story).aspectRatioScale,
        CardScale.ratioScale(ExportSize.story),
      );
    });
  });

  group('CardTheme', () {
    final pair = [const Color(0xFF1A237E), const Color(0xFF00695C)];

    test('uses a near-black background and white foreground', () {
      final theme = CardTheme.from(colorPair: pair);
      expect(theme.bg, CardTheme.nearBlackBg);
      expect(theme.onBg, Colors.white);
      expect(theme.surface, isNot(CardTheme.nearBlackBg));
    });

    test('honours the accent override', () {
      const override = Color(0xFFFF3366);
      final theme = CardTheme.from(colorPair: pair, accentOverride: override);
      expect(theme.accent, override);
      expect(theme.surface, isA<Color>());
    });

    test('kit modes select home, away or a derived third colour', () {
      final home = CardTheme.from(colorPair: pair, kitMode: KitMode.home);
      final away = CardTheme.from(colorPair: pair, kitMode: KitMode.away);
      final third = CardTheme.from(colorPair: pair, kitMode: KitMode.third);
      expect(home.kitColor, pair.first);
      expect(away.kitColor, pair.last);
      expect(third.kitColor, isNot(pair.first));
    });

    test('an empty colour pair still yields a usable theme', () {
      final theme = CardTheme.from(colorPair: const []);
      expect(theme.teamPrimary, isA<Color>());
      expect(theme.accent, isA<Color>());
    });

    test('CardConfig exposes the derived theme', () {
      const config = CardConfig(colorPair: [Color(0xFFFF0000)]);
      expect(config.theme.teamPrimary, const Color(0xFFFF0000));
    });
  });
}
