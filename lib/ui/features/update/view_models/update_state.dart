import '../../../../data/models/app_release.dart';

enum UpdateStatus {
  /// Nothing has been checked yet, or an automatic check finished quietly.
  idle,

  /// A lookup is in flight.
  checking,

  /// The installed build is the latest published release.
  upToDate,

  /// A newer release exists and the user has not skipped it.
  available,

  /// A manual check failed; [UpdateState.errorMessage] explains why.
  error,
}

/// State of the in-app update check.
class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.currentVersion = '',
    this.currentBuildNumber = '',
    this.latestRelease,
    this.errorMessage,
    this.downloadInProgress = false,
    this.downloadProgress = 0,
    this.downloadedApkPath,
    this.publicDownloadPath,
    this.publishError,
    this.installInProgress = false,
    this.installError,
    this.installPermissionRequired = false,
    this.downloadError,
  });

  final UpdateStatus status;

  /// The installed `versionName`, e.g. `1.2.0`.
  final String currentVersion;

  /// The installed `versionCode`, e.g. `42`.
  final String currentBuildNumber;

  final AppRelease? latestRelease;

  /// Only set for [UpdateStatus.error] (manual checks).
  final String? errorMessage;

  /// True while the newer APK is being downloaded for an install.
  final bool downloadInProgress;

  /// 0..1 fraction of the APK downloaded so far.
  final double downloadProgress;

  /// Absolute path of the verified, app-private APK used by FileProvider for
  /// the install. The dialog swaps the Update action for Install once set.
  final String? downloadedApkPath;

  /// User-visible location of the copy in the public Downloads folder, e.g.
  /// `Download/oreamnos-v1.2.0.apk`.
  final String? publicDownloadPath;

  /// Set when the public Downloads copy could not be written. The install can
  /// still proceed from the verified app-private file.
  final String? publishError;

  /// True while the verified APK is being handed to the OS installer.
  final bool installInProgress;

  /// Specific native failure reason shown in the dialog after an Install tap.
  final String? installError;

  /// True when the failure was a missing "Install unknown apps" grant.
  final bool installPermissionRequired;

  /// Set when a download failed; cleared when a new download starts.
  final String? downloadError;

  bool get isChecking => status == UpdateStatus.checking;

  /// `Version 1.2.0 (build 42)`, or an empty string before [PackageInfo]
  /// resolves.
  String get versionLabel {
    if (currentVersion.isEmpty) return '';
    final build = currentBuildNumber.isEmpty
        ? ''
        : ' (build $currentBuildNumber)';
    return 'Version $currentVersion$build';
  }

  UpdateState copyWith({
    UpdateStatus? status,
    String? currentVersion,
    String? currentBuildNumber,
    AppRelease? latestRelease,
    bool clearLatest = false,
    String? errorMessage,
    bool clearError = false,
    bool? downloadInProgress,
    double? downloadProgress,
    String? downloadedApkPath,
    bool clearDownloadedApkPath = false,
    String? publicDownloadPath,
    bool clearPublicDownloadPath = false,
    String? publishError,
    bool clearPublishError = false,
    bool? installInProgress,
    String? installError,
    bool clearInstallError = false,
    bool? installPermissionRequired,
    String? downloadError,
    bool clearDownloadError = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      latestRelease: clearLatest ? null : (latestRelease ?? this.latestRelease),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      downloadInProgress: downloadInProgress ?? this.downloadInProgress,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedApkPath: clearDownloadedApkPath
          ? null
          : (downloadedApkPath ?? this.downloadedApkPath),
      publicDownloadPath: clearPublicDownloadPath
          ? null
          : (publicDownloadPath ?? this.publicDownloadPath),
      publishError: clearPublishError
          ? null
          : (publishError ?? this.publishError),
      installInProgress: installInProgress ?? this.installInProgress,
      installError: clearInstallError
          ? null
          : (installError ?? this.installError),
      installPermissionRequired:
          installPermissionRequired ?? this.installPermissionRequired,
      downloadError: clearDownloadError
          ? null
          : (downloadError ?? this.downloadError),
    );
  }
}
