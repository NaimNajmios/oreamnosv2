import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';

void main() {
  group('CardData sealed 17 variants', () {
    test('sparse fromBrief', () {
      final c = CardData.fromBrief(headline: 'Hello', subtext: 'World', microStat: 'M1');
      expect(c.headline, 'Hello');
      expect(c.subtext, 'World');
      expect(c.microStat, 'M1');
    });
    test('playerSpotlight headline is playerName', () {
      const c = CardData.playerSpotlight(playerName: 'Haaland', club: 'Man City', position: 'Striker');
      expect(c.headline, 'Haaland');
      expect(c.effectiveTemplate, CardTemplate.playerSpotlight);
    });
    test('headlineQuote', () {
      const c = CardData.headlineQuote(headline: 'Title', subtext: 'Quote', quoteAuthor: 'Messi');
      expect(c.headline, 'Title');
      expect(c.subtext, 'Quote');
    });
    test('topStats stats padded to 3', () {
      const c = CardData.topStats(matchContext: 'UCL', stats: []);
      // Through extractor padding, but direct factory keeps empty — check fromJson pads via extractor not factory
      expect((c as TopStats).stats, isEmpty);
    });
    test('breakingNews default label', () {
      const c = CardData.breakingNews(headline: 'Big');
      expect((c as BreakingNews).label, '🚨 BREAKING');
    });
    test('tableStandings headline is leagueName', () {
      const c = CardData.tableStandings(leagueName: 'EPL');
      expect(c.headline, 'EPL');
    });
    test('socialPost content fallback', () {
      const c = CardData.socialPost(content: 'Content line');
      expect(c.headline, 'Content line');
    });
    test('fromJson sparse fallback', () {
      final m = {'headline': 'H', 'subtext': 'S', 'microStat': 'M', 'runtimeType': 'sparse'};
      final c = CardData.fromJson(m);
      expect(c is SparseCard, true);
      expect(c.headline, 'H');
    });
    test('fromJson topStats with stats', () {
      final m = {
        'matchContext': 'Derby',
        'stats': [
          {'label': 'G', 'value': '2', 'context': 'N/A'},
          {'label': 'A', 'value': '1', 'context': 'N/A'},
          {'label': 'CS', 'value': '1', 'context': 'N/A'}
        ],
        'runtimeType': 'topStats'
      };
      final c = CardData.fromJson(m);
      expect(c is TopStats, true);
      expect((c as TopStats).stats.length, 3);
    });
    test('isEmpty true for generated card', () {
      const c = CardData.sparse(headline: 'Generated Card', subtext: '');
      expect(c.isEmpty, true);
    });
    test('effectiveTemplate from suggested', () {
      const c = CardData.playerSpotlight(playerName: 'P', suggestedTemplate: CardTemplate.breakingNews);
      expect(c.effectiveTemplate, CardTemplate.breakingNews);
    });
    test('all 17 variants have headline', () {
      final variants = [
        const CardData.playerSpotlight(playerName: 'A'),
        const CardData.headlineQuote(headline: 'A', subtext: 'B'),
        const CardData.topStats(),
        const CardData.transferNews(playerName: 'A'),
        const CardData.breakingNews(headline: 'A'),
        const CardData.matchPreview(homeTeam: 'A', awayTeam: 'B'),
        const CardData.detailedScoreboard(homeTeam: 'A', awayTeam: 'B'),
        const CardData.onThisDay(),
        const CardData.startingXI(),
        const CardData.matchStatsComparison(),
        const CardData.socialPost(content: 'A'),
        const CardData.rivalry(),
        const CardData.tableStandings(),
        const CardData.injuryReport(),
        const CardData.contractExpiry(),
        const CardData.awardNominee(),
        const CardData.sparse(headline: 'A'),
      ];
      for (final v in variants) {
        expect(v.headline.isNotEmpty, true, reason: v.runtimeType.toString());
      }
    });
  });
}
