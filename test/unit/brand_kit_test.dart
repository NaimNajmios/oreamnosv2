import 'package:flutter/material.dart' hide CardTheme;
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/theme/card_theme.dart';
import 'package:oreamnos/domain/models/club_profile.dart';
import 'package:oreamnos/domain/models/card_config.dart';

void main() {
  group('ClubProfile', () {
    final profile = ClubProfile(
      name: 'Johor Darul Ta\'zim',
      handle: '@jdt',
      roster: const [
        RosterPlayer(name: 'Salah', photoPath: '/photos/salah.png'),
      ],
    );

    test('selects kit colours', () {
      expect(profile.colorsFor(KitMode.home), profile.homeColors);
      expect(profile.colorsFor(KitMode.away), profile.awayColors);
      expect(profile.colorsFor(KitMode.third), profile.thirdColors);
    });

    test('round-trips through JSON', () {
      final restored = ClubProfile.fromJson(profile.toJson());
      expect(restored.name, profile.name);
      expect(restored.handle, '@jdt');
      expect(restored.roster.single.name, 'Salah');
      expect(restored.colorsFor(KitMode.home).first, profile.homeColors.first);
    });

    test('CardConfig kit mode feeds CardTheme', () {
      const config = CardConfig(
        colorPair: [Color(0xFFFF0000), Color(0xFF0000FF)],
        kitMode: KitMode.away,
      );
      expect(config.theme.kitColor, const Color(0xFF0000FF));
      expect(config.theme.kitMode, KitMode.away);
    });
  });
}
