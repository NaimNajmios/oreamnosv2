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
