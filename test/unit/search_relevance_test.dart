import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/domain/models/research_context.dart';
import 'package:oreamnos/domain/models/tavily_search.dart';
import 'package:oreamnos/domain/services/search_query_planner.dart';
import 'package:oreamnos/domain/services/search_relevance_guard.dart';
import 'package:oreamnos/domain/services/search_result_ranker.dart';

const _guard = SearchRelevanceGuard();
const _ranker = SearchResultRanker();

TavilySearchResult _result({
  String title = 'Bukayo Saka scores twice as Arsenal beat Chelsea 3-1',
  String url = 'https://www.bbc.com/sport/football/12345',
  String content =
      'Bukayo Saka reached 15 goals this season as Arsenal won 3-1.',
  double score = 0.95,
  String? publishedDate,
}) {
  return TavilySearchResult(
    title: title,
    url: url,
    content: content,
    score: score,
    publishedDate: publishedDate,
  );
}

SearchPlan _plan([
  String text = 'Bukayo Saka scored twice as Arsenal beat Chelsea',
]) {
  return const SearchQueryPlanner().plan(text: text);
}

void main() {
  group('SearchRelevanceGuard', () {
    test('keeps a result that overlaps the article entities', () {
      final decision = _guard.evaluate(result: _result(), plan: _plan());

      expect(decision.keep, isTrue);
      expect(decision.reason, 'relevant');
      expect(decision.entityOverlap, greaterThan(0));
    });

    test('drops high-score unrelated results', () {
      final decision = _guard.evaluate(
        result: _result(
          title: 'Kuala Lumpur traffic update',
          url: 'https://example.com/traffic',
          content: 'Road closures today around the city centre.',
          score: 0.99,
        ),
        plan: _plan(),
      );

      expect(decision.keep, isFalse);
      expect(decision.reason, anyOf(contains('overlap'), 'key name missing'));
    });

    test('drops a generic roundup that never mentions the key name', () {
      final plan = const SearchQueryPlanner().plan(
        text:
            'Max Dowman is set to sign a three-year contract with Arsenal '
            'after his 17th birthday.',
      );
      final decision = _guard.evaluate(
        result: _result(
          title: 'Friday football transfer roundup: Calvert-Lewin, Musiala',
          url: 'https://www.skysports.com/football/news/11661/roundup',
          content:
              'The latest deals include Calvert-Lewin and Nottingham Forest '
              'targets, plus Bayern midfielder Musiala.',
          score: 0.92,
        ),
        plan: plan,
      );

      expect(plan.keyEntity, 'Max Dowman');
      expect(decision.keep, isFalse);
      expect(decision.reason, 'key name missing');
    });

    test('drops results below the score floor', () {
      final decision = _guard.evaluate(
        result: _result(score: 0.2),
        plan: _plan(),
      );

      expect(decision.keep, isFalse);
      expect(decision.reason, 'score below floor');
    });

    test('drops excluded domains and noisy titles', () {
      final excluded = _guard.evaluate(
        result: _result(url: 'https://facebook.com/post/1'),
        plan: _plan(),
      );
      expect(excluded.keep, isFalse);
      expect(excluded.reason, 'excluded domain');

      final noisy = _guard.evaluate(
        result: _result(
          title: 'Best betting odds for the match',
          url: 'https://random-blog.example.com/p',
        ),
        plan: _plan(),
      );
      expect(noisy.keep, isFalse);
      expect(noisy.reason, 'noise title');
    });

    test(
      'relaxed pass rescues borderline coverage but not unrelated results',
      () {
        final borderline = _guard.evaluate(
          result: _result(
            title: 'Saka scores for Arsenal',
            content: 'Bukayo Saka found the net as Arsenal beat Chelsea.',
            score: 0.32,
          ),
          plan: _plan(),
          minScore: AppConstants.tavilyRelaxedMinScore,
          relaxed: true,
        );
        expect(borderline.keep, isTrue);

        final unrelated = _guard.evaluate(
          result: _result(
            title: 'Kuala Lumpur traffic update',
            url: 'https://example.com/traffic',
            content: 'Road closures today around the city centre.',
            score: 0.95,
          ),
          plan: _plan(),
          minScore: AppConstants.tavilyRelaxedMinScore,
          relaxed: true,
        );
        expect(unrelated.keep, isFalse);
      },
    );
  });

  group('SearchResultRanker', () {
    ScoredSearchResult scored(
      TavilySearchResult result, {
      bool keep = true,
      double relevance = 0.8,
    }) {
      return ScoredSearchResult(
        result: result,
        decision: SearchGuardDecision(
          keep: keep,
          relevance: relevance,
          reason: keep ? 'relevant' : 'dropped',
        ),
      );
    }

    test('deduplicates canonical URLs and near-identical titles', () {
      final ranked = _ranker.rank([
        scored(_result()),
        scored(
          _result(url: 'https://bbc.com/sport/football/12345?utm_source=x'),
        ),
        scored(
          _result(
            title: 'Bukayo Saka scores twice as Arsenal beat Chelsea 3-1!',
            url: 'https://www.other.com/a',
          ),
        ),
      ]);

      expect(ranked, hasLength(1));
      expect(ranked.single.outlet, 'BBC Sport');
    });

    test('sorts by relevance and keeps only the configured cap', () {
      final items = [
        for (var i = 0; i < 6; i++)
          scored(
            _result(
              title: 'Result number $i',
              url: 'https://example.com/$i',
              score: 0.5 + i / 100,
              publishedDate: '2026-11-2${i}T10:00:00Z',
            ),
            relevance: i / 10,
          ),
      ];

      final ranked = _ranker.rank(items);

      expect(ranked.length, 4);
      expect(ranked.first.title, 'Result number 5');
    });

    test('drops results that failed the guard', () {
      final ranked = _ranker.rank([scored(_result(), keep: false)]);
      expect(ranked, isEmpty);
    });

    test('canonicalUrl strips tracking parameters', () {
      expect(
        SearchResultRanker.canonicalUrl(
          'https://WWW.Example.com/a/b/?utm_source=x&id=7',
        ),
        'example.com/a/b?id=7',
      );
    });
  });

  group('ResearchSource', () {
    test('display label uses the outlet, never the URL', () {
      final source = ResearchSource(
        title: 'Saka scores',
        url: 'https://www.bbc.com/sport/1',
        snippet: 'text',
        outlet: 'BBC Sport',
      );
      expect(source.displayLabel, 'BBC Sport');
      expect(source.domain, 'www.bbc.com');
    });
  });
}
