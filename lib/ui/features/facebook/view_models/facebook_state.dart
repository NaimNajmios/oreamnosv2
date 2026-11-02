import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

/// Connection + publishing state for the Facebook feature.
///
/// Seeded synchronously from prefs in `FacebookNotifier.build` (async
/// secure-storage reads refresh it right after), following the plain
/// `SettingsState` convention — no codegen needed here.
enum FacebookConnectionStatus {
  /// No token stored.
  notConnected,

  /// Token + Page identity persisted and assumed valid.
  connected,

  /// A publish call hit a 190 — publish UI should push a reconnect.
  expired,
}

class FacebookUiState {
  const FacebookUiState({
    this.status = FacebookConnectionStatus.notConnected,
    this.pageId = '',
    this.pageName = '',
  });

  final FacebookConnectionStatus status;
  final String pageId;
  final String pageName;

  bool get isConnected => status == FacebookConnectionStatus.connected;
  bool get isNotConnected => status == FacebookConnectionStatus.notConnected;
  bool get isExpired => status == FacebookConnectionStatus.expired;

  /// Settings-tile / compose-chip subtitle copy.
  String get subtitle {
    return switch (status) {
      FacebookConnectionStatus.connected => 'Connected · $pageName',
      FacebookConnectionStatus.expired => 'Token expired — reconnect your Page',
      FacebookConnectionStatus.notConnected => 'Not connected',
    };
  }

  FacebookUiState copyWith({
    FacebookConnectionStatus? status,
    String? pageId,
    String? pageName,
  }) {
    return FacebookUiState(
      status: status ?? this.status,
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
    );
  }
}

/// Draft lifecycle for the compose screen.
enum FacebookComposePhase {
  /// Editing text/attachment.
  editing,

  /// Publish call in flight.
  publishing,

  /// Post created — success panel shows the permalink.
  published,

  /// Last publish attempt failed; [FacebookComposeState.error] holds why.
  publishError,
}

class FacebookComposeState {
  const FacebookComposeState({
    this.text = '',
    this.imagePath,
    this.phase = FacebookComposePhase.editing,
    this.result,
    this.error,
  });

  /// Plain text ready for the feed (markdown already stripped at
  /// `startDraft`); the user may have edited it further.
  final String text;
  final String? imagePath;
  final FacebookComposePhase phase;
  final FacebookPublishResult? result;
  final FacebookApiException? error;

  bool get isPublishing => phase == FacebookComposePhase.publishing;
  bool get isPublished => phase == FacebookComposePhase.published;

  /// Publish button gate: text required; publishing state and phase handled
  /// by the caller (offline is checked at publish time, not here).
  bool get hasText => text.trim().isNotEmpty;

  FacebookComposeState copyWith({
    String? text,
    Object? imagePath = _sentinel,
    FacebookComposePhase? phase,
    Object? result = _sentinel,
    Object? error = _sentinel,
  }) {
    return FacebookComposeState(
      text: text ?? this.text,
      imagePath: imagePath == _sentinel ? this.imagePath : imagePath as String?,
      phase: phase ?? this.phase,
      result: result == _sentinel
          ? this.result
          : result as FacebookPublishResult?,
      error: error == _sentinel ? this.error : error as FacebookApiException?,
    );
  }

  static const Object _sentinel = Object();
}
