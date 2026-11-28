import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/search_query_planner.dart';

void main() {
  const planner = SearchQueryPlanner();

  test('prefers the page title over the first sentence', () {
    final plan = planner.plan(
      text: 'Kuala Lumpur: Johor Darul Ta\'zim extended their unbeaten run with a 2-1 win over Selangor.',
      pageTitle: 'JDT beat Selangor 2-1 in Liga Super',
    );

    expect(plan.headline, 'JDT beat Selangor 2-1 in Liga Super');
    expect(plan.primary.query, contains('JDT beat Selangor'));
    expect(plan.primary.query.toLowerCase(), isNot(contains('stats')));
  });

  test('adds an English alternative for Malay input', () {
    final plan = planner.plan(
      text: 'JDT kalah kepada Selangor dalam perlawanan Liga Super malam ini.',
    );

    expect(plan.primary.query.toLowerCase(), contains('jdt'));
    expect(plan.queries.length, greaterThan(1));
    final english = plan.alternatives.first;
    expect(english.options.language, 'en');
    expect(english.query.toLowerCase(), contains('johor darul ta\'zim'));
  });

  test('result intent uses general topic and Malaysia country', () {
    final plan = planner.plan(
      text: 'Johor Darul Ta\'zim kalah 1-2 kepada Selangor malam ini.',
    );

    expect(plan.intent, 'result');
    expect(plan.primary.options.topic, 'general');
    expect(plan.primary.options.country, 'malaysia');
    expect(plan.primary.options.timeRange, 'day');
  });

  test('transfer intent uses news topic and a week window', () {
    final plan = planner.plan(
      text: 'Harimau Malaya announce a new signing as the player agrees a contract.',
    );

    expect(plan.intent, 'transfer');
    expect(plan.primary.options.topic, 'news');
    expect(plan.primary.options.timeRange, 'week');
    expect(plan.primary.options.country, isNull);
  });

  test('never blindly appends stats to a headline', () {
    final plan = planner.plan(
      text: 'Arsenal defeated Chelsea 3-1 at the Emirates Stadium.',
    );

    expect(plan.primary.query.toLowerCase(), isNot(contains('stats')));
  });

  test('query length stays within the configured ceiling', () {
    final long = List.filled(120, 'word').join(' ');
    final plan = planner.plan(text: long);

    expect(plan.primary.query.length, lessThanOrEqualTo(220));
  });

  test('drops TYPE/DATE/POST CONTENT template headers before planning', () {
    final plan = planner.plan(
      text:
          'TYPE: Transfer\n'
          'DATE: Fri Nov 28\n'
          'POST CONTENT: Max Dowman is set to sign a new contract with Arsenal '
          'after his 17th birthday. The England wonderkid has been training '
          'with the first team.',
    );
    final query = plan.primary.query.toLowerCase();

    expect(plan.headline.toLowerCase(), contains('max dowman'));
    expect(query, contains('dowman'));
    expect(query, contains('arsenal'));
    for (final junk in ['type', 'date', 'post content', 'fri', 'nov']) {
      expect(query, isNot(contains(junk)), reason: 'query was $query');
    }
    expect(plan.keyEntity, 'Max Dowman');
  });

  test('handles an inline POST CONTENT header on a single line', () {
    final plan = planner.plan(
      text:
          'TYPE DATE Fri Nov POST CONTENT Max Dowman Arsenal contract talks '
          'continue this week.',
    );

    expect(plan.primary.query.toLowerCase(), contains('max dowman'));
    expect(plan.primary.query.toLowerCase(), isNot(contains('post content')));
  });

  test('AI-suggested entities and queries override the heuristic query', () {
    final plan = const SearchQueryPlanner().planWith(
      text: 'TYPE DATE Fri Nov POST CONTENT Max Dowman deal news',
      entities: const ['Max Dowman', 'Arsenal'],
      queries: const ['Max Dowman Arsenal first professional contract'],
    );

    expect(
      plan.primary.query,
      'Max Dowman Arsenal first professional contract',
    );
    expect(plan.keyEntity, 'Max Dowman');
    expect(plan.entities, contains('Arsenal'));
    expect(plan.primary.options.topic, anyOf('news', 'general'));
    expect(
      plan.queries.any((q) => q.options.includeDomains.isNotEmpty),
      isTrue,
    );
  });

  test('prefers a trusted-domain fallback query', () {
    final plan = planner.plan(
      text:
          'Max Dowman is expected to sign a three-year deal with Arsenal '
          'this month.',
    );

    expect(
      plan.queries.any((q) => q.options.includeDomains.isNotEmpty),
      isTrue,
    );
    expect(
      plan.queries
          .firstWhere((q) => q.options.includeDomains.isNotEmpty)
          .options
          .includeDomains,
      contains('bbc.com'),
    );
  });
}
