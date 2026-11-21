import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:oreamnos/data/models/app_release.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/update_service.dart';
import 'package:oreamnos/ui/features/update/view_models/update_state.dart';
import 'package:oreamnos/ui/features/update/view_models/update_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUpdateService extends UpdateService {
  _FakeUpdateService();

  AppRelease? release;
  Object? error;
  int calls = 0;
  int downloads = 0;
  final List<String> downloadTargets = <String>[];

  @override
  Future<AppRelease?> fetchLatestRelease() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return release;
  }

  @override
  Future<void> downloadUpdate(
    AppRelease release,
    String targetPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    downloads++;
    downloadTargets.add(targetPath);
    final failure = error;
    if (failure != null) throw failure;
    onProgress?.call(512, 1024);
  }
}

AppRelease _release(String tag) => AppRelease.fromJson({
  'tag_name': tag,
  'name': 'Oreamnos $tag',
  'body': 'Release notes',
  'html_url': 'https://example.test/$tag',
  'published_at': '2026-11-01T00:00:00Z',
  'prerelease': false,
  'assets': [
    {
      'name': 'app.apk',
      'browser_download_url': 'https://example.test/app.apk',
      'size': 1024,
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PreferencesService preferences;
  late _FakeUpdateService service;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    preferences = PreferencesService(
      prefs: prefs,
      secureStorage: const FlutterSecureStorage(),
    );
    service = _FakeUpdateService();
    now = DateTime(2026, 11, 20, 12);
  });

  ProviderContainer containerWith({String version = '1.0.0'}) {
    final container = ProviderContainer(
      overrides: [
        updateServiceProvider.overrideWithValue(service),
        updatePreferencesProvider.overrideWithValue(preferences),
        updateClockProvider.overrideWithValue(() => now),
        updatePackageInfoProvider.overrideWithValue(
          () async => PackageInfo(
            appName: 'oreamnos',
            packageName: 'com.najmi.oreamnos',
            version: version,
            buildNumber: '7',
          ),
        ),
        updateCacheDirProvider.overrideWithValue(
          () async => Directory.systemTemp,
        ),
        updateInstallerProvider.overrideWithValue((apkPath) async => true),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<UpdateNotifier> readyNotifier(ProviderContainer container) async {
    final notifier = container.read(updateViewModelProvider.notifier);
    await notifier.init();
    return notifier;
  }

  test('init reads the installed version', () async {
    final container = containerWith(version: '1.2.3');
    await readyNotifier(container);
    final state = container.read(updateViewModelProvider);

    expect(state.currentVersion, '1.2.3');
    expect(state.currentBuildNumber, '7');
    expect(state.versionLabel, 'Version 1.2.3 (build 7)');
  });

  test('an automatic check is throttled for six hours', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    await preferences.setUpdateLastCheck(
      now.subtract(const Duration(hours: 1)),
    );

    service.release = _release('v2.0.0');
    await notifier.checkForUpdates();

    expect(service.calls, 0);
    expect(container.read(updateViewModelProvider).status, UpdateStatus.idle);
  });

  test('a newer release is offered', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    service.release = _release('v1.1.0');

    await notifier.checkForUpdates();

    final state = container.read(updateViewModelProvider);
    expect(state.status, UpdateStatus.available);
    expect(state.latestRelease?.version, '1.1.0');
    expect(preferences.updateLastCheck, isNotNull);
  });

  test(
    'startDownload downloads the APK, then exposes the install action',
    () async {
      final container = containerWith();
      final notifier = await readyNotifier(container);
      final release = _release('v1.1.0');
      service.release = release;
      await notifier.checkForUpdates(manual: true);
      expect(
        container.read(updateViewModelProvider).status,
        UpdateStatus.available,
      );

      await notifier.startDownload(release: release);

      final state = container.read(updateViewModelProvider);
      expect(state.downloadInProgress, isFalse);
      expect(state.downloadProgress, 1);
      expect(state.downloadedApkPath, isNotNull);
      expect(state.downloadError, isNull);
      expect(service.downloads, 1);
      expect(service.downloadTargets.single, contains('updates'));

      final installed = await notifier.installUpdate();
      expect(installed, isTrue);

      final after = container.read(updateViewModelProvider);
      expect(after.installInProgress, isFalse);
      expect(after.downloadedApkPath, isNull);
    },
  );

  test(
    'a failed download surfaces an error and keeps no install path',
    () async {
      final container = containerWith();
      final notifier = await readyNotifier(container);
      service.error = const UpdateCheckException(
        'The download timed out.',
        isNetwork: true,
      );

      await notifier.startDownload(release: _release('v1.1.0'));

      final state = container.read(updateViewModelProvider);
      expect(state.downloadInProgress, isFalse);
      expect(state.downloadError, contains('timed out'));
      expect(state.downloadedApkPath, isNull);
    },
  );

  test('the same or an older release is up to date', () async {
    for (final tag in ['v1.0.0', 'v0.9.0']) {
      final container = containerWith();
      final notifier = await readyNotifier(container);
      service
        ..calls = 0
        ..release = _release(tag);

      // Manual so the shared preferences timestamp from the previous
      // iteration does not throttle this one.
      await notifier.checkForUpdates(manual: true);

      expect(
        container.read(updateViewModelProvider).status,
        UpdateStatus.upToDate,
        reason: tag,
      );
    }
  });

  test('no published release yet counts as up to date', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    service.release = null;

    await notifier.checkForUpdates();

    expect(
      container.read(updateViewModelProvider).status,
      UpdateStatus.upToDate,
    );
  });

  test('a skipped tag is ignored by automatic checks', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    await preferences.setUpdateSkippedTag('v1.1.0');
    service.release = _release('v1.1.0');

    await notifier.checkForUpdates();

    final state = container.read(updateViewModelProvider);
    expect(state.status, UpdateStatus.idle);
    expect(state.latestRelease, isNull);
  });

  test('a manual check still reports a skipped tag', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    await preferences.setUpdateSkippedTag('v1.1.0');
    service.release = _release('v1.1.0');

    await notifier.checkForUpdates(manual: true);

    expect(
      container.read(updateViewModelProvider).status,
      UpdateStatus.available,
    );
  });

  test('skipThisVersion records the tag and clears the prompt', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    service.release = _release('v1.1.0');
    await notifier.checkForUpdates(manual: true);

    await notifier.skipThisVersion();

    expect(preferences.updateSkippedTag, 'v1.1.0');
    expect(container.read(updateViewModelProvider).status, UpdateStatus.idle);
  });

  test('automatic failures stay silent', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    service.error = const UpdateCheckException(
      "Couldn't reach GitHub.",
      isNetwork: true,
    );

    await notifier.checkForUpdates();

    final state = container.read(updateViewModelProvider);
    expect(state.status, UpdateStatus.idle);
    expect(state.errorMessage, isNull);
  });

  test('manual failures are surfaced', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    service.error = const UpdateCheckException(
      "Couldn't reach GitHub.",
      isNetwork: true,
    );

    await notifier.checkForUpdates(manual: true);

    final state = container.read(updateViewModelProvider);
    expect(state.status, UpdateStatus.error);
    expect(state.errorMessage, contains('GitHub'));
  });

  test('manual rate limiting is surfaced with its own message', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    service.error = const UpdateRateLimitedException();

    await notifier.checkForUpdates(manual: true);

    final state = container.read(updateViewModelProvider);
    expect(state.status, UpdateStatus.error);
    expect(state.errorMessage!.toLowerCase(), contains('rate'));
  });

  test('a manual check ignores the throttle', () async {
    final container = containerWith();
    final notifier = await readyNotifier(container);
    await preferences.setUpdateLastCheck(now);
    service.release = _release('v1.1.0');

    await notifier.checkForUpdates(manual: true);

    expect(service.calls, 1);
    expect(
      container.read(updateViewModelProvider).status,
      UpdateStatus.available,
    );
  });

  test('an unreadable installed version is a manual-only error', () async {
    final container = ProviderContainer(
      overrides: [
        updateServiceProvider.overrideWithValue(service),
        updatePreferencesProvider.overrideWithValue(preferences),
        updateClockProvider.overrideWithValue(() => now),
        updatePackageInfoProvider.overrideWithValue(
          () async => throw StateError('no plugin'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(updateViewModelProvider.notifier);
    await notifier.init();

    await notifier.checkForUpdates();
    expect(container.read(updateViewModelProvider).status, UpdateStatus.idle);

    await notifier.checkForUpdates(manual: true);
    expect(container.read(updateViewModelProvider).status, UpdateStatus.error);
    expect(service.calls, 0);
  });
}
