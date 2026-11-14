import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_insights_service.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/domain/models/facebook_post_insights.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingInsights extends FacebookInsightsService {
  _FailingInsights() : super(ApiClient());

  @override
  Future<FacebookPostInsights> fetch({
    required String postId,
    required String token,
  }) async {
    throw const FacebookApiException(
      kind: FacebookApiErrorKind.insightsUnavailable,
      message: 'Insights are unavailable for this post.',
    );
  }

  @override
  Future<FacebookPostInsights> fetchEngagement({
    required String postId,
    required String token,
  }) async {
    throw const FacebookApiException(
      kind: FacebookApiErrorKind.network,
      message: "Can't reach Facebook right now.",
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const token = 'EAAtokenShouldNeverBeLogged12345';

  late SharedPreferences rawPrefs;
  late FacebookHistoryService history;
  late LogService logs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    getIt.allowReassignment = true;

    rawPrefs = await SharedPreferences.getInstance();
    final prefs = PreferencesService(
      prefs: rawPrefs,
      secureStorage: const FlutterSecureStorage(),
    );
    await prefs.setFacebookPageToken(token);
    history = FacebookHistoryService(rawPrefs);
    logs = LogService(rawPrefs);
    logs.clear();

    getIt.registerLazySingleton<PreferencesService>(() => prefs);
    getIt.registerLazySingleton<FacebookInsightsService>(_FailingInsights.new);
    getIt.registerLazySingleton<FacebookHistoryService>(() => history);
    getIt.registerLazySingleton<LogService>(() => logs);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('Facebook insight refresh logging', () {
    test('a typed failure is logged with a duration and no token', () async {
      final record = await history.recordPublish(
        postId: 'post_1',
        message: 'FT: JDT 4 - 1 #FAM',
        permalink: 'https://www.facebook.com/post_1',
        hasImage: false,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(facebookHistoryProvider);

      final error = await container
          .read(facebookHistoryProvider.notifier)
          .refreshInsights(record.id);

      expect(error, 'Insights are unavailable for this post.');
      final entry = logs.logs.lastWhere(
        (log) => log.tag == 'Facebook' && log.message.startsWith('Insights'),
      );
      expect(entry.level, 'WARN');
      expect(entry.message, contains('ms'));
      expect(entry.message, isNot(contains(token)));
      expect(entry.message, isNot(contains('EAA')));
    });

    test('engagement failures are logged separately', () async {
      final record = await history.recordPublish(
        postId: 'post_2',
        message: 'Second post',
        permalink: 'https://www.facebook.com/post_2',
        hasImage: false,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(facebookHistoryProvider);

      final error = await container
          .read(facebookHistoryProvider.notifier)
          .refreshEngagement(record.id);

      expect(error, "Can't reach Facebook right now.");
      final entry = logs.logs.lastWhere(
        (log) => log.tag == 'Facebook' && log.message.startsWith('Engagement'),
      );
      expect(entry.level, 'WARN');
      expect(entry.message, contains('ms'));
    });
  });
}
