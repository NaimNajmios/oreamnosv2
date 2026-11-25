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

/// Outcome of a native install handoff. A boolean cannot distinguish a launch
/// from a permission problem, so the native side reports an error code.
class UpdateInstallResult {
  const UpdateInstallResult({required this.ok, this.code, this.message});

  final bool ok;
  final String? code;
  final String? message;

  static const success = UpdateInstallResult(ok: true);

  /// The user must enable "Install unknown apps" in Android settings.
  bool get needsPermission => code == 'INSTALL_PERMISSION_REQUIRED';
}

/// Seam for the native install handoff; tests override it.
final updateInstallerProvider =
    Provider<Future<UpdateInstallResult> Function(String apkPath)>(
      (ref) => _installViaChannel,
    );

/// Seam for publishing the verified APK into the public Downloads folder.
/// Returns the user-visible location, e.g. `Download/oreamnos-v1.2.0.apk`.
final updateDownloadsPublisherProvider =
    Provider<Future<String> Function(String apkPath)>(
      (ref) => _publishToDownloadsViaChannel,
    );

/// Seam for opening Android's "Install unknown apps" settings screen.
final updateInstallSettingsProvider = Provider<Future<bool> Function()>(
  (ref) => _openInstallSettingsViaChannel,
);

final MethodChannel _updateChannel = MethodChannel('oreamnos_update_installer');

Future<UpdateInstallResult> _installViaChannel(String apkPath) async {
  try {
    final installed = await _updateChannel.invokeMethod<bool>(
      'install',
      <String, String>{'apkPath': apkPath},
    );
    return installed == true
        ? UpdateInstallResult.success
        : const UpdateInstallResult(
            ok: false,
            message: "Couldn't install the update.",
          );
  } on PlatformException catch (error) {
    return UpdateInstallResult(
      ok: false,
      code: error.code,
      message: _installErrorMessage(error.code, error.message),
    );
  } catch (_) {
    return const UpdateInstallResult(
      ok: false,
      message: "Couldn't install the update.",
    );
  }
}

String _installErrorMessage(String code, String? nativeMessage) {
  switch (code) {
    case 'INSTALL_PERMISSION_REQUIRED':
      return 'Allow Oreamnos to install unknown apps, then tap Install again.';
    case 'INSTALL_NO_HANDLER':
      return 'No app on this device can install the update.';
    case 'APK_NOT_FOUND':
      return 'The downloaded update file is missing. Download it again.';
    case 'DOWNLOAD_PERMISSION_REQUIRED':
      return 'Storage permission is needed to save the update to Downloads.';
    default:
      return nativeMessage ?? "Couldn't install the update.";
  }
}

Future<String> _publishToDownloadsViaChannel(String apkPath) async {
  final published = await _updateChannel.invokeMethod<String>(
    'saveToDownloads',
    <String, String>{'apkPath': apkPath},
  );
  if (published == null || published.isEmpty) {
    throw const UpdateCheckException(
      'The update could not be saved to the Downloads folder.',
    );
  }
  return published;
}

Future<bool> _openInstallSettingsViaChannel() async {
  final opened = await _updateChannel.invokeMethod<bool>('openInstallSettings');
  return opened == true;
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

  /// Downloads the latest release APK into the system Downloads folder
  /// (path_provider `getDownloadsDirectory()`, the generic Android
  /// `DIRECTORY_DOWNLOADS`), falling back to the cache when there is none,
  /// and verifies its SHA-256. Returns the saved path.
  Future<String> downloadLatestApk() async {
    final release = await ref.read(updateServiceProvider).fetchLatestRelease();
    if (release == null || !release.hasApk) {
      throw const UpdateCheckException('No APK is available to download.');
    }
    final dir = await ref.read(updateApkDirectoryProvider)();
    final targetPath = '${dir.path}/oreamnos-${release.tag}.apk';
    await ref.read(updateServiceProvider).downloadUpdate(release, targetPath);
    return targetPath;
  }

  /// Downloads the newer APK from GitHub Releases into the app-private downloads
  /// directory (falling back to the cache when there is none) and verifies its
  /// SHA-256. The verified file is then copied into the public Downloads folder
  /// through the native `saveToDownloads` channel method so it is visible in the
  /// phone's Files app. Installing still uses the app-private original, which is
  /// the path FileProvider is configured to serve.
  ///
  /// On success [UpdateState.downloadedApkPath] points at the install source and
  /// [UpdateState.publicDownloadPath] at the user-visible copy. A publishing
  /// failure is reported through [UpdateState.publishError] but does not block
  /// the install. On failure the error is surfaced through
  /// [UpdateState.downloadError].
  Future<void> startDownload({required AppRelease release}) async {
    if (state.downloadInProgress) return;
    state = state.copyWith(
      downloadInProgress: true,
      downloadProgress: 0,
      installInProgress: false,
      downloadedApkPath: null,
      downloadError: null,
      clearPublicDownloadPath: true,
      clearPublishError: true,
      clearInstallError: true,
      installPermissionRequired: false,
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

      String? publicPath;
      String? publishError;
      try {
        publicPath = await ref.read(updateDownloadsPublisherProvider)(
          targetPath,
        );
      } on UpdateCheckException catch (error) {
        publishError = error.message;
      } on PlatformException catch (error) {
        publishError =
            error.message ??
            'The APK was saved inside the app but could not be copied to the '
                'Downloads folder.';
      } catch (_) {
        publishError =
            'The APK was saved inside the app but could not be '
            'copied to the Downloads folder.';
      }

      state = state.copyWith(
        downloadInProgress: false,
        downloadProgress: 1,
        downloadedApkPath: targetPath,
        publicDownloadPath: publicPath,
        publishError: publishError,
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

  /// Hands the verified app-private APK to the OS installer via the native
  /// `oreamnos_update_installer` channel and reports any specific failure.
  Future<UpdateInstallResult> installUpdate() async {
    final path = state.downloadedApkPath;
    if (path == null || state.installInProgress) {
      return const UpdateInstallResult(
        ok: false,
        message: 'Download the update before installing it.',
      );
    }
    state = state.copyWith(
      installInProgress: true,
      clearInstallError: true,
      installPermissionRequired: false,
    );
    try {
      final result = await ref.read(updateInstallerProvider)(path);
      if (result.ok) {
        state = state.copyWith(
          installInProgress: false,
          downloadedApkPath: null,
          clearDownloadedApkPath: true,
          clearPublicDownloadPath: true,
          clearInstallError: true,
          installPermissionRequired: false,
        );
      } else {
        state = state.copyWith(
          installInProgress: false,
          installError: result.message,
          installPermissionRequired: result.needsPermission,
        );
      }
      return result;
    } catch (_) {
      const failure = UpdateInstallResult(
        ok: false,
        message: "Couldn't install the update.",
      );
      state = state.copyWith(
        installInProgress: false,
        installError: failure.message,
      );
      return failure;
    }
  }

  /// Opens Android's "Install unknown apps" settings after a permission
  /// failure, so the user can grant it and retry without leaving the app.
  Future<void> openInstallSettings() async {
    final opened = await ref.read(updateInstallSettingsProvider)();
    if (!opened) {
      state = state.copyWith(
        installError: 'Could not open the installation settings.',
      );
    }
  }
}
