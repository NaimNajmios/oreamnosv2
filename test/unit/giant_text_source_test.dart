import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/services/giant_text_source.dart';

void main() {
  group('GiantTextSource', () {
    test('uses the player surname', () {
      expect(
        GiantTextSource.forCardData(
          CardData.playerSpotlight(playerName: 'Mohamed Salah'),
        ),
        'SALAH',
      );
    });

    test('uses the last word of a quote headline without punctuation', () {
      expect(
        GiantTextSource.forCardData(
          CardData.headlineQuote(
            headline: 'GOAL! Alisson scores.',
            subtext: '',
          ),
        ),
        'SCORES',
      );
    });

    test('returns null when there is no data or no usable word', () {
      expect(GiantTextSource.forCardData(null), isNull);
      expect(
        GiantTextSource.forCardData(CardData.playerSpotlight(playerName: '')),
        isNull,
      );
      expect(
        GiantTextSource.forCardData(
          CardData.socialPost(content: 'Hello', metrics: ''),
        ),
        isNull,
      );
    });
  });
}
