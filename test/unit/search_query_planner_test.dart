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
}
