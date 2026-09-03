import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/services/card_data_normalizer.dart';

void main() {
  group('CardTemplate Extended Contract Tests', () {
    test('fromIntent resolves all 17 template intents correctly', () {
      for (final template in CardTemplate.values) {
        final intent = template.templateIntent;
        final resolved = CardTemplate.fromIntent(intent);
        expect(resolved, template, reason: 'Intent " should resolve to ');
      }
    });

    test('fromLegacy maps historical template names properly', () {
      expect(
        CardTemplate.fromLegacy('headlineQuote'),
        CardTemplate.headlineQuote,
      );
      expect(
        CardTemplate.fromLegacy('breakingNews'),
        CardTemplate.breakingNews,
      );
      expect(
        CardTemplate.fromLegacy('transferNews'),
        CardTemplate.transferNews,
      );
      expect(CardTemplate.fromLegacy('topStats'), CardTemplate.topStats);
      expect(
        CardTemplate.fromLegacy('matchPreview'),
        CardTemplate.matchPreview,
      );
      expect(CardTemplate.fromLegacy('startingXI'), CardTemplate.startingXI);
      expect(
        CardTemplate.fromLegacy('detailedScoreboard'),
        CardTemplate.detailedScoreboard,
      );
      expect(
        CardTemplate.fromLegacy('tableStandings'),
        CardTemplate.tableStandings,
      );
      expect(
        CardTemplate.fromLegacy('playerSpotlight'),
        CardTemplate.playerSpotlight,
      );
      expect(CardTemplate.fromLegacy('rivalry'), CardTemplate.rivalry);
      expect(
        CardTemplate.fromLegacy('injuryReport'),
        CardTemplate.injuryReport,
      );
      expect(
        CardTemplate.fromLegacy('contractExpiry'),
        CardTemplate.contractExpiry,
      );
      expect(
        CardTemplate.fromLegacy('awardNominee'),
        CardTemplate.awardNominee,
      );
      expect(
        CardTemplate.fromLegacy('matchStatsComparison'),
        CardTemplate.matchStatsComparison,
      );
      expect(CardTemplate.fromLegacy('onThisDay'), CardTemplate.onThisDay);
      expect(CardTemplate.fromLegacy('socialPost'), CardTemplate.socialPost);
      expect(
        CardTemplate.fromLegacy('nonexistent_legacy'),
        CardTemplate.socialPost,
      );
    });

    test(
      'CardDataNormalizer produces clean values and strips quotes/placeholders',
      () {
        expect(CardDataNormalizer.cleanValue('Arda Guler'), 'Arda Guler');
        expect(CardDataNormalizer.cleanValue('Real Madrid'), 'Real Madrid');
        expect(CardDataNormalizer.cleanValue('N/A'), '');
        expect(CardDataNormalizer.cleanValue('none'), '');
        expect(CardDataNormalizer.cleanValue('null'), '');
        expect(
          CardDataNormalizer.cleanValue(' Stripped Text '),
          'Stripped Text',
        );
      },
    );

    test(
      'All 17 CardData variants can be constructed and serialized to JSON',
      () {
        final variants = <CardData>[
          const CardData.playerSpotlight(
            playerName: 'Haaland',
            club: 'City',
            position: 'Striker',
          ),
          const CardData.headlineQuote(
            headline: 'Quote title',
            subtext: 'Quote body',
            quoteAuthor: 'Pep',
          ),
          const CardData.topStats(
            matchContext: 'UCL',
            stats: [StatItem(label: 'G', value: '2')],
          ),
          const CardData.transferNews(
            playerName: 'Bellingham',
            fromTeam: 'Dortmund',
            toTeam: 'Real',
          ),
          const CardData.breakingNews(headline: 'Breaking', subtext: 'Details'),
          const CardData.matchPreview(homeTeam: 'JDT', awayTeam: 'Selangor'),
          const CardData.detailedScoreboard(
            homeTeam: 'JDT',
            awayTeam: 'Selangor',
            homeScore: 2,
            awayScore: 1,
          ),
          const CardData.onThisDay(headline: 'Historic', yearsAgo: 10),
          const CardData.startingXI(teamName: 'JDT', formation: '4-3-3'),
          const CardData.matchStatsComparison(
            homeTeam: 'A',
            awayTeam: 'B',
            stats: [
              ComparisonStat(label: 'Poss', homeValue: '55%', awayValue: '45%'),
            ],
          ),
          const CardData.socialPost(content: 'Hello world', handle: '@jdt'),
          const CardData.rivalry(player1Name: 'Messi', player2Name: 'Ronaldo'),
          const CardData.tableStandings(
            leagueName: 'EPL',
            standings: [
              TableRow(
                position: 1,
                teamName: 'City',
                played: 10,
                won: 7,
                drawn: 2,
                lost: 1,
                points: 23,
              ),
            ],
          ),
          const CardData.injuryReport(
            teamName: 'JDT',
            injuries: [
              InjuryItem(playerName: 'A', injury: 'ACL', status: 'Out'),
            ],
          ),
          const CardData.contractExpiry(
            teamName: 'JDT',
            expiringPlayers: [
              ContractPlayer(
                playerName: 'A',
                position: 'MF',
                expiresIn: '2026',
              ),
            ],
          ),
          const CardData.awardNominee(
            awardName: 'Ballon d Or',
            nominees: [
              NomineeItem(
                playerName: 'Haaland',
                club: 'City',
                achievement: 'Golden Boot',
              ),
            ],
          ),
          const CardData.sparse(
            headline: 'Sparse Title',
            subtext: 'Sparse Subtext',
          ),
        ];

        expect(variants.length, 17);
        for (final v in variants) {
          final json = v.toJson();
          expect(json, isNotEmpty);
        }
      },
    );
  });
}
