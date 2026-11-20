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
  });

  final UpdateStatus status;

  /// The installed `versionName`, e.g. `1.2.0`.
  final String currentVersion;

  /// The installed `versionCode`, e.g. `42`.
  final String currentBuildNumber;

  final AppRelease? latestRelease;

  /// Only set for [UpdateStatus.error] (manual checks).
  final String? errorMessage;

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
  }) {
    return UpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      latestRelease: clearLatest ? null : (latestRelease ?? this.latestRelease),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
