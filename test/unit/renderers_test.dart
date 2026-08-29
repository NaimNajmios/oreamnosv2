import 'package:flutter/material.dart' hide TableRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/renderers/card_canvas_dispatcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/data/services/card_data_extractor.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    final prefs = await createMockPrefs();
    final prefService = createTestPreferencesService(prefs);
    await getIt.reset();
    getIt.registerLazySingleton<PreferencesService>(() => prefService);
    getIt.registerLazySingleton<UsageService>(() => createTestUsageService(prefs));
    getIt.registerLazySingleton<ExportService>(() => ExportService());
    getIt.registerLazySingleton<CardDataExtractor>(() => CardDataExtractor());
  });

  group('CardCanvasDispatcher 17 renderers', () {
    final config = CardConfig(colorPair: [Colors.blue, Colors.purple]);
    final variants = [
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
        injuries: [InjuryItem(playerName: 'A', injury: 'ACL', status: 'Out')],
      ),
      const CardData.contractExpiry(
        teamName: 'JDT',
        expiringPlayers: [
          ContractPlayer(playerName: 'A', position: 'MF', expiresIn: '2026'),
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
      const CardData.sparse(headline: 'Sparse', subtext: 'Sub', microStat: 'M'),
    ];

    for (int i = 0; i < variants.length; i++) {
      testWidgets('renders variant $i ${variants[i].runtimeType}', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 360,
                  child: CardCanvasDispatcher(
                    cardData: variants[i],
                    config: config,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CardCanvasDispatcher), findsOneWidget);
        // Check headline text appears
        expect(
          find.textContaining(variants[i].headline.split(' ').first),
          findsWidgets,
        );
      });
    }
  });
}
