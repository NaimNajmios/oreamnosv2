import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/services/card_data_normalizer.dart';

void main() {
  group('CardDataNormalizer', () {
    test('cleanValue strips placeholder tokens', () {
      expect(CardDataNormalizer.cleanValue('N/A'), '');
      expect(CardDataNormalizer.cleanValue('na'), '');
      expect(CardDataNormalizer.cleanValue('-'), '');
      expect(CardDataNormalizer.cleanValue('—'), '');
      expect(CardDataNormalizer.cleanValue('null'), '');
      expect(CardDataNormalizer.cleanValue('none'), '');
      expect(CardDataNormalizer.cleanValue('TBD'), '');
      expect(CardDataNormalizer.cleanValue('tiada'), '');
      expect(CardDataNormalizer.cleanValue('  N/A  '), '');
      expect(CardDataNormalizer.cleanValue('Kylian Mbappé'), 'Kylian Mbappé');
      expect(CardDataNormalizer.cleanValue(null), '');
    });

    test('normalize truncates strings exceeding maxChars cleanly', () {
      final raw = {
        'playerName': 'This is an extremely long player name that exceeds twenty five characters',
        'fromTeam': 'PSG',
        'toTeam': 'Real Madrid',
      };
      final result = CardDataNormalizer.normalize(
        CardTemplate.transferNews,
        raw,
      );
      final cleanedName = result.json['playerName'] as String;
      expect(cleanedName.length, lessThanOrEqualTo(26)); // 25 + ellipsis
      expect(cleanedName.endsWith('…'), isTrue);
    });

    test('normalize tracks missing required keys', () {
      final raw = {
        'playerName': 'Erling Haaland',
        'fromTeam': 'N/A', // Placeholder -> empty
        'toTeam': '', // Empty
      };
      final result = CardDataNormalizer.normalize(
        CardTemplate.transferNews,
        raw,
      );
      expect(result.missingKeys, contains('fromTeam'));
      expect(result.missingKeys, contains('toTeam'));
      expect(result.missingKeys.contains('playerName'), isFalse);
    });

    test('normalize resolves alias keys when primary key is missing', () {
      final raw = {
        'player': 'Cole Palmer', // alias for playerName
        'club': 'Chelsea', // alias for fromTeam in transferNews
        'newClub': 'Bayern', // alias for toTeam
      };
      final result = CardDataNormalizer.normalize(
        CardTemplate.transferNews,
        raw,
      );
      expect(result.json['playerName'], 'Cole Palmer');
      expect(result.json['fromTeam'], 'Chelsea');
      expect(result.json['toTeam'], 'Bayern');
      expect(result.missingKeys.contains('playerName'), isFalse);
    });

    test(
      'normalize preserves numeric 0 for valid scores but flags missing names',
      () {
        final raw = {
          'homeTeam': 'Liverpool',
          'awayTeam': '',
          'homeScore': 0,
          'awayScore': 0,
        };
        final result = CardDataNormalizer.normalize(
          CardTemplate.detailedScoreboard,
          raw,
        );
        expect(result.missingKeys, contains('awayTeam'));
        expect(result.missingKeys.contains('homeScore'), isFalse);
        expect(result.missingKeys.contains('awayScore'), isFalse);
      },
    );
  });
}
