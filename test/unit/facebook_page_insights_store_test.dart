import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_page_insights_store.dart';
import 'package:oreamnos/domain/models/facebook_page_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';

FacebookPageInsights _insights({
  String pageId = 'page-1',
  int rangeDays = 28,
  List<PageInsightPoint> points = const [],
  List<PageInsightPoint> previousPoints = const [],
}) => FacebookPageInsights(
  pageId: pageId,
  points: points,
  fetchedAt: DateTime(2026, 11, 12, 9),
  rangeDays: rangeDays,
  previousPoints: previousPoints,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FacebookPageInsightsStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FacebookPageInsightsStore(prefs);
  });

  group('FacebookPageInsightsStore', () {
    test('keeps ranges for the same Page isolated', () async {
      await store.save(_insights(rangeDays: 7, points: const []));
      await store.save(
        _insights(
          rangeDays: 90,
          points: [PageInsightPoint(day: DateTime(2026, 11, 1), mediaViews: 4)],
        ),
      );

      expect(store.load('page-1', days: 7)!.rangeDays, 7);
      final ninety = store.load('page-1', days: 90)!;
      expect(ninety.rangeDays, 90);
      expect(ninety.points.single.mediaViews, 4);
    });

    test('falls back to a legacy cache only for 28 days', () async {
      final legacy = _insights(
        points: [PageInsightPoint(day: DateTime(2026, 11, 1), mediaViews: 2)],
      );
      await prefs.setString(
        'facebook_page_insights_page-1',
        '{"pageId":"page-1","points":[{"day":"2026-11-01T00:00:00.000",'
            '"mediaViews":2}],"fetchedAt":"2026-11-12T09:00:00.000Z"}',
      );

      expect(store.load('page-1')!.totalMediaViews, legacy.totalMediaViews);
      expect(store.load('page-1', days: 28)!.rangeDays, 28);
      expect(store.load('page-1', days: 90), isNull);
    });

    test('clear removes every range for one Page only', () async {
      await store.save(_insights(rangeDays: 7));
      await store.save(_insights(rangeDays: 28));
      await store.save(_insights(pageId: 'page-2', rangeDays: 28));

      await store.clear('page-1');

      expect(store.load('page-1', days: 7), isNull);
      expect(store.load('page-1', days: 28), isNull);
      expect(store.load('page-2', days: 28), isNotNull);
    });
  });

  group('FacebookPageInsights totals', () {
    test('sums flows and takes the latest follower count', () {
      final insights = _insights(
        points: [
          PageInsightPoint(
            day: DateTime(2026, 11, 1),
            mediaViews: 10,
            engagements: 1,
            follows: 100,
          ),
          PageInsightPoint(
            day: DateTime(2026, 11, 2),
            mediaViews: 5,
            engagements: 2,
            follows: 130,
          ),
        ],
        previousPoints: [
          PageInsightPoint(
            day: DateTime(2026, 10, 30),
            mediaViews: 4,
            engagements: 3,
            follows: 90,
          ),
        ],
      );

      expect(insights.totalMediaViews, 15);
      expect(insights.totalEngagements, 3);
      expect(insights.totalFollows, 130);
      expect(insights.hasPrevious, isTrue);
      expect(insights.previousTotals.mediaViews, 4);
      expect(insights.previousTotals.follows, 90);
    });

    test('survives a JSON round trip with previous data', () {
      final insights = _insights(
        rangeDays: 90,
        points: [PageInsightPoint(day: DateTime(2026, 11, 1), mediaViews: 8)],
        previousPoints: [
          PageInsightPoint(day: DateTime(2026, 8, 1), mediaViews: 3),
        ],
      );

      final restored = FacebookPageInsights.fromJson(insights.toJson());

      expect(restored.rangeDays, 90);
      expect(restored.totalMediaViews, 8);
      expect(restored.previousTotals.mediaViews, 3);
      expect(restored.previousPoints.single.day, DateTime(2026, 8, 1));
    });

    test('copyWith replaces only the previous window', () {
      final insights = _insights(
        previousPoints: [
          PageInsightPoint(day: DateTime(2026, 8, 1), mediaViews: 3),
        ],
      );

      final updated = insights.copyWith(
        previousPoints: const [],
        previousUnavailableMetrics: const ['page_follows'],
      );

      expect(updated.points, insights.points);
      expect(updated.hasPrevious, isFalse);
      expect(updated.previousUnavailableMetrics, ['page_follows']);
    });
  });
}
