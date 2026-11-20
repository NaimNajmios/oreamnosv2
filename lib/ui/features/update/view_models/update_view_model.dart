import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/version_compare.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../data/services/update_service.dart';
import 'update_state.dart';

/// Indirection so tests can supply a fixed installed version.
final updatePackageInfoProvider = Provider<Future<PackageInfo> Function()>(
  (ref) => PackageInfo.fromPlatform,
);

/// Indirection so tests can supply a clock for the throttle.
final updateClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final updateServiceProvider = Provider<UpdateService>(
  (ref) => getIt<UpdateService>(),
);

final updatePreferencesProvider = Provider<PreferencesService>(
  (ref) => getIt<PreferencesService>(),
);

final updateViewModelProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

/// Checks GitHub Releases for a newer build.
///
/// Automatic checks are throttled and fail silently; manual checks report a
/// friendly error. Nothing here throws into the widget tree.
class UpdateNotifier extends Notifier<UpdateState> {
  static const Duration throttle = Duration(hours: 6);

  bool _loadedInfo = false;

  @override
  UpdateState build() => const UpdateState();

  /// Reads the installed version once. Failure leaves the label empty rather
  /// than surfacing an error — the app still works without it.
  Future<void> init() async {
    if (_loadedInfo) return;
    _loadedInfo = true;
    try {
      final info = await ref.read(updatePackageInfoProvider)();
      state = state.copyWith(
        currentVersion: info.version,
        currentBuildNumber: info.buildNumber,
      );
    } catch (_) {
      // PackageInfo is a plugin; a missing implementation is not fatal.
    }
  }

  Future<void> checkForUpdates({bool manual = false}) async {
    if (state.status == UpdateStatus.checking) return;
    if (!_loadedInfo) await init();

    final prefs = ref.read(updatePreferencesProvider);
    final now = ref.read(updateClockProvider)();

    if (!manual) {
      final last = prefs.updateLastCheck;
      if (last != null && now.difference(last) < throttle) return;
    }

    if (state.currentVersion.isEmpty) {
      if (manual) {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: "Couldn't read the installed version.",
        );
      }
      return;
    }

    state = state.copyWith(status: UpdateStatus.checking, clearError: true);

    try {
      final release = await ref
          .read(updateServiceProvider)
          .fetchLatestRelease();
      await prefs.setUpdateLastCheck(now);

      if (release == null ||
          !isNewerVersion(release.version, state.currentVersion)) {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          clearLatest: true,
        );
        return;
      }

      final skipped = prefs.updateSkippedTag;
      if (!manual && skipped != null && skipped == release.tag) {
        state = state.copyWith(status: UpdateStatus.idle, clearLatest: true);
        return;
      }

      state = state.copyWith(
        status: UpdateStatus.available,
        latestRelease: release,
      );
    } on UpdateRateLimitedException catch (error) {
      _fail(manual, error.message);
    } on UpdateCheckException catch (error) {
      _fail(manual, error.message);
    } catch (_) {
      _fail(manual, 'The update check failed.');
    }
  }

  void _fail(bool manual, String message) {
    state = manual
        ? state.copyWith(status: UpdateStatus.error, errorMessage: message)
        : state.copyWith(status: UpdateStatus.idle, clearError: true);
  }

  /// Suppresses the automatic prompt for the release currently on screen.
  /// A manual check still reports it.
  Future<void> skipThisVersion() async {
    final release = state.latestRelease;
    if (release == null) return;
    await ref.read(updatePreferencesProvider).setUpdateSkippedTag(release.tag);
    state = state.copyWith(status: UpdateStatus.idle, clearLatest: true);
  }

  /// Opens the APK download, falling back to the release page.
  Future<bool> openDownload() async {
    final release = state.latestRelease;
    if (release == null) return false;
    final target = release.hasApk ? release.apkUrl! : release.htmlUrl;
    if (target.isEmpty) return false;
    try {
      return await launchUrl(
        Uri.parse(target),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
