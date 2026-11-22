import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/version_compare.dart';
import '../../../../data/models/app_release.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../data/services/update_service.dart';
import 'update_state.dart';

/// Indirection so tests can supply a fixed installed version.
final updatePackageInfoProvider = Provider<Future<PackageInfo> Function()>(
  (ref) => PackageInfo.fromPlatform,
);

/// Indirection so tests can supply the downloads directory for the update
/// APK. Falls back to the cache directory when the system reports no
/// downloads directory.
final updateApkDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => () async {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
    final temp = await getTemporaryDirectory();
    return Directory('${temp.path}/updates');
  },
);

/// Seam for the native install handoff; tests override it.
final updateInstallerProvider = Provider<Future<bool> Function(String apkPath)>(
  (ref) => _installViaChannel,
);

final MethodChannel _installChannel = MethodChannel(
  'oreamnos_update_installer',
);

Future<bool> _installViaChannel(String apkPath) async {
  final installed = await _installChannel.invokeMethod<bool>(
    'install',
    <String, String>{'apkPath': apkPath},
  );
  return installed == true;
}

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

  /// Downloads the newer APK from GitHub Releases into the app downloads
  /// directory (falling back to the cache when there is none) and
  /// verifies its SHA-256. On success [UpdateState.downloadedApkPath] points
  /// at the verified file and the dialog swaps the Update action for an
  /// Install action. On failure the error is surfaced through
  /// [UpdateState.downloadError].
  Future<void> startDownload({required AppRelease release}) async {
    if (state.downloadInProgress) return;
    state = state.copyWith(
      downloadInProgress: true,
      downloadProgress: 0,
      installInProgress: false,
      downloadedApkPath: null,
      downloadError: null,
    );

    final dir = await ref.read(updateApkDirectoryProvider)();
    final targetPath = '${dir.path}/oreamnos-${release.tag}.apk';
    try {
      await ref
          .read(updateServiceProvider)
          .downloadUpdate(
            release,
            targetPath,
            onProgress: (received, total) {
              final fraction = total > 0
                  ? (received / total).clamp(0.0, 1.0)
                  : 0.0;
              state = state.copyWith(downloadProgress: fraction);
            },
          );
      state = state.copyWith(
        downloadInProgress: false,
        downloadProgress: 1,
        downloadedApkPath: targetPath,
      );
    } on UpdateCheckException catch (error) {
      state = state.copyWith(
        downloadInProgress: false,
        downloadProgress: 0,
        downloadError: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        downloadInProgress: false,
        downloadProgress: 0,
        downloadError: 'The update download failed.',
      );
    }
  }

  /// Hands the verified downloaded APK to the OS installer via the native
  /// `oreamnos_update_installer` channel. Returns whether the install intent
  /// was accepted.
  Future<bool> installUpdate() async {
    final path = state.downloadedApkPath;
    if (path == null || state.installInProgress) return false;
    state = state.copyWith(installInProgress: true);
    try {
      final installed = await ref.read(updateInstallerProvider)(path);
      if (installed) {
        state = state.copyWith(
          installInProgress: false,
          downloadedApkPath: null,
          clearDownloadedApkPath: true,
        );
        return true;
      }
      state = state.copyWith(installInProgress: false);
      return false;
    } catch (_) {
      state = state.copyWith(installInProgress: false);
      return false;
    }
  }
}
