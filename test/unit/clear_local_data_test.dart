import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/daily_usage_service.dart';
import 'package:oreamnos/data/services/facebook_draft_store.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_storage_service.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/usage_service.dart';
import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late SharedPreferences rawPrefs;
  late LogService logService;
  late UsageService usageService;
  late DailyUsageService dailyUsage;
  late FacebookDraftStore drafts;

  Future<ProviderContainer> waitForLoad() async {
    final container = ProviderContainer();
    container.read(settingsViewModelProvider);
    for (var i = 0; i < 100; i++) {
      if (container.read(settingsViewModelProvider).isInitialized) {
        return container;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Settings state never initialized');
  }

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('oreamnos_docs');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return docs.path;
          }
          if (call.method == 'getTemporaryDirectory') {
            return Directory.systemTemp.path;
          }
          return null;
        });
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    rawPrefs = await SharedPreferences.getInstance();
    await getIt.reset();
    getIt.allowReassignment = true;
    logService = LogService(rawPrefs);
    usageService = UsageService(rawPrefs);
    dailyUsage = DailyUsageService(rawPrefs);
    drafts = FacebookDraftStore(rawPrefs);
    getIt.registerLazySingleton<PreferencesService>(
      () => PreferencesService(
        prefs: rawPrefs,
        secureStorage: const FlutterSecureStorage(),
      ),
    );
    getIt.registerLazySingleton<LogService>(() => logService);
    getIt.registerLazySingleton<UsageService>(() => usageService);
    getIt.registerLazySingleton<DailyUsageService>(() => dailyUsage);
    getIt.registerLazySingleton<FacebookDraftStore>(() => drafts);
    getIt.registerLazySingleton<FacebookStorageService>(
      () => FacebookStorageService(FacebookHistoryService(rawPrefs), drafts),
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (docs.existsSync()) await docs.delete(recursive: true);
    await getIt.reset();
  });

  test('clearLocalData wipes logs, usage history and drafts', () async {
    final container = await waitForLoad();
    final notifier = container.read(settingsViewModelProvider.notifier);

    // Seed local data.
    logService.info('seed log');
    expect(logService.logs, isNotEmpty);
    await usageService.logUsage(
      UsageLog(
        id: 'u1',
        timestamp: DateTime(2026, 11, 1, 12),
        providerId: 'gemini',
        latencyMs: 120,
        estimatedTokens: 500,
        isSuccess: true,
      ),
    );
    expect(usageService.logs, isNotEmpty);
    await dailyUsage.recordRequest('gemini', 'gemini-2.5-flash');
    expect(dailyUsage.todayQuotaFor('gemini'), isNotEmpty);
    await drafts.save(
      FacebookDraftRecord(
        id: 'd1',
        text: 'Draft',
        media: const [],
        pageId: '1',
        pageName: 'Trace',
        mode: 'now',
        updatedAt: DateTime.now(),
      ),
    );
    expect(drafts.loadAll(), isNotEmpty);

    await notifier.clearLocalData();

    expect(logService.logs, isEmpty);
    expect(usageService.logs, isEmpty);
    expect(dailyUsage.todayQuotaFor('gemini'), isEmpty);
    expect(drafts.loadAll(), isEmpty);
  });
}
