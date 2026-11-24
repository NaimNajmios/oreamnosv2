import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_monetization_service.dart';
import 'package:oreamnos/data/services/facebook_page_insights_service.dart';
import 'package:oreamnos/data/services/facebook_page_insights_store.dart';
import 'package:oreamnos/data/services/facebook_page_service.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/domain/models/facebook_monetization.dart';
import 'package:oreamnos/domain/models/facebook_page_insights.dart';
import 'package:oreamnos/ui/features/publish/view_models/facebook_performance_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubPageInsights extends FacebookPageInsightsService {
  _StubPageInsights({this.fail = false}) : super(ApiClient());

  final bool fail;
  int fetches = 0;

  @override
  Future<FacebookPageInsights> fetch({
    required String pageId,
    required String token,
    int days = 28,
  }) async {
    fetches++;
    if (fail) {
      throw const FacebookApiException(
        kind: FacebookApiErrorKind.network,
        message: 'offline',
      );
    }
    return FacebookPageInsights(
      pageId: pageId,
      points: const [],
      fetchedAt: DateTime.now(),
      rangeDays: days,
    );
  }

  @override
  Future<FacebookPageInsights> fetchPrevious({
    required String pageId,
    required String token,
    int days = 28,
  }) async {
    return FacebookPageInsights(
      pageId: pageId,
      points: const [],
      fetchedAt: DateTime.now(),
      rangeDays: days,
    );
  }
}

class _StubMonetization extends FacebookMonetizationService {
  _StubMonetization({this.fail = false}) : super(ApiClient());

  final bool fail;

  @override
  Future<FacebookMonetizationSnapshot> fetch({
    required String pageId,
    required String token,
    int days = 28,
  }) async {
    if (fail) throw Exception('earnings unavailable');
    return FacebookMonetizationSnapshot(
      pageId: pageId,
      totalEarnings: 4.2,
      totalApproximateEarnings: null,
      fetchedAt: DateTime.now(),
      currency: 'USD',
    );
  }
}

/// Minimal stand-in for a typed Graph failure.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences rawPrefs;
  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    rawPrefs = await SharedPreferences.getInstance();
    prefs = PreferencesService(
      prefs: rawPrefs,
      secureStorage: const FlutterSecureStorage(),
    );
    await prefs.setFacebookPageTokenFor('page_1', 'EAAtoken');
    await prefs.setFacebookPages([
      const FacebookPage(id: 'page_1', name: 'Trace'),
    ]);
    await prefs.setFacebookActivePageId('page_1');

    await getIt.reset();
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<PreferencesService>(() => prefs);
    getIt.registerLazySingleton<ApiClient>(ApiClient.new);
    getIt.registerLazySingleton<FacebookPublisherService>(
      () => FacebookPublisherService(ApiClient()),
    );
    getIt.registerLazySingleton<FacebookPageService>(
      () => FacebookPageService(ApiClient()),
    );
    getIt.registerLazySingleton<FacebookPageInsightsStore>(
      () => FacebookPageInsightsStore(rawPrefs),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  ProviderContainer build({
    FacebookPageInsightsService? insights,
    FacebookMonetizationService? monetization,
  }) {
    getIt.registerLazySingleton<FacebookPageInsightsService>(
      () => insights ?? _StubPageInsights(),
    );
    getIt.registerLazySingleton<FacebookMonetizationService>(
      () => monetization ?? _StubMonetization(),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(facebookPerformanceProvider);
    return container;
  }

  group('FacebookPerformanceNotifier', () {
    test('an earnings failure still delivers page performance', () async {
      final container = build(monetization: _StubMonetization(fail: true));

      final error = await container
          .read(facebookPerformanceProvider.notifier)
          .refresh();

      expect(error, isNull);
      final state = container.read(facebookPerformanceProvider);
      expect(state.error, isNull);
      expect(state.data?.pageId, 'page_1');
      expect(state.monetization, isNull);
    });

    test('a Graph failure surfaces the typed message', () async {
      final container = build(insights: _StubPageInsights(fail: true));

      final error = await container
          .read(facebookPerformanceProvider.notifier)
          .refresh();

      expect(error, 'offline');
      expect(container.read(facebookPerformanceProvider).error, 'offline');
    });

    test('earnings are stored alongside the performance window', () async {
      // Earnings are opt-in (default off).
      await prefs.setFacebookMonetizationEnabled(true);
      final container = build();

      await container.read(facebookPerformanceProvider.notifier).refresh();

      final state = container.read(facebookPerformanceProvider);
      expect(state.monetization?.totalEarnings, 4.2);
      expect(state.data?.pageId, 'page_1');
    });

    test('earnings are not requested while the opt-in is off', () async {
      final container = build();
      await container.read(facebookPerformanceProvider.notifier).refresh();

      final state = container.read(facebookPerformanceProvider);
      expect(state.monetization, isNull);
      expect(state.error, isNull);
    });

    test('a selected range persists and is reused', () async {
      final container = build();

      await container
          .read(facebookPerformanceProvider.notifier)
          .refresh(days: 7);

      expect(prefs.facebookPerformanceDays, 7);
      expect(container.read(facebookPerformanceProvider).days, 7);

      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      expect(restored.read(facebookPerformanceProvider).days, 7);
    });
  });

  group('compactMetric', () {
    test('formats null, small, thousands and millions', () {
      expect(compactMetric(null), '—');
      expect(compactMetric(0), '0');
      expect(compactMetric(999), '999');
      expect(compactMetric(1000), '1.0k');
      expect(compactMetric(1500), '1.5k');
      expect(compactMetric(2_500_000), '2.5m');
    });
  });

  group('computePerformanceDeltas', () {
    FacebookInsightTotals totals({int? mediaViews, int? engagements}) =>
        FacebookInsightTotals(mediaViews: mediaViews, engagements: engagements);

    test('returns positive deltas when the window grew', () {
      final deltas = computePerformanceDeltas(
        current: totals(mediaViews: 2500, engagements: 40),
        previous: totals(mediaViews: 1000, engagements: 20),
      );
      expect(deltas, hasLength(2));
      expect(deltas[0].label, 'Media views');
      expect(deltas[0].value, '+1.5k');
      expect(deltas[0].negative, isFalse);
      expect(deltas[1].label, 'Engagements');
      expect(deltas[1].value, '+20');
      expect(deltas[1].negative, isFalse);
    });

    test('marks drops as negative', () {
      final deltas = computePerformanceDeltas(
        current: totals(mediaViews: 1000, engagements: 10),
        previous: totals(mediaViews: 2000, engagements: 50),
      );
      expect(deltas, hasLength(2));
      expect(deltas[0].value, '-1.0k');
      expect(deltas[0].negative, isTrue);
      expect(deltas[1].value, '-40');
      expect(deltas[1].negative, isTrue);
    });

    test('reads zero differences as same', () {
      final deltas = computePerformanceDeltas(
        current: totals(mediaViews: 100, engagements: 5),
        previous: totals(mediaViews: 100, engagements: 5),
      );
      expect(deltas.map((delta) => delta.value), everyElement('same'));
      expect(deltas.every((delta) => !delta.negative), isTrue);
    });

    test('skips metrics that are missing in either window', () {
      expect(
        computePerformanceDeltas(
          current: const FacebookInsightTotals(),
          previous: const FacebookInsightTotals(),
        ),
        isEmpty,
      );
      final oneSided = computePerformanceDeltas(
        current: totals(mediaViews: 500),
        previous: totals(mediaViews: 100),
      );
      expect(oneSided, hasLength(1));
      expect(oneSided[0].label, 'Media views');
      expect(oneSided[0].value, '+400');
    });
  });
}
