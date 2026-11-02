/// Failure taxonomy for Facebook Graph API publishing calls.
enum FacebookApiErrorKind {
  /// Token rejected or expired (code 190) — user must reconnect the Page.
  expiredToken,

  /// Missing Page roles or publish permission (codes 200, 10).
  permission,

  /// Per-Page or app-level throttle (codes 4, 17, 32, 613).
  rateLimit,

  /// Identical message+attachment on the same Page within a window (506).
  duplicate,

  /// Transport failure with no Graph error body (timeout, offline).
  network,

  /// Anything else, including unexpected server responses.
  unknown,
}

/// Typed exception carrying the Graph error code/subcode, a human-readable
/// message mapped from the code, and the failure kind the UI branches on
/// (e.g. a 190 shows a Reconnect action instead of Retry).
class FacebookApiException implements Exception {
  const FacebookApiException({
    required this.kind,
    required this.message,
    this.code,
    this.subcode,
  });

  final FacebookApiErrorKind kind;

  /// Human-friendly copy shown in the compose screen / dialogs.
  final String message;

  /// Graph error code (e.g. 190), null for transport failures.
  final int? code;

  /// Graph `error_subcode` when present (e.g. 1487391).
  final int? subcode;

  /// True when the fix is reconnecting the Page (token expired/invalidated).
  bool get needsReconnect => kind == FacebookApiErrorKind.expiredToken;

  @override
  String toString() =>
      'FacebookApiException(kind: $kind, code: $code'
      '${subcode != null ? '/$subcode' : ''}, message: $message)';

  /// Maps a Graph error body (from an HTTP error response) or a transport
  /// failure with no body into a typed exception. `body` is the parsed JSON
  /// response payload; `isNetworkFailure` marks timeouts/connection errors
  /// where no response ever arrived.
  static FacebookApiException fromGraph(
    int? statusCode,
    Map<String, dynamic>? body, {
    bool isNetworkFailure = false,
  }) {
    if (isNetworkFailure) {
      return const FacebookApiException(
        kind: FacebookApiErrorKind.network,
        message: 'No connection. Check your internet and try again.',
      );
    }
    final error =
        (body?['error'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final code = (error['code'] as num?)?.toInt();
    final subcode = (error['error_subcode'] as num?)?.toInt();
    final rawMessage =
        error['message']?.toString() ?? 'Facebook request failed.';
    final kind = _classify(code, subcode, statusCode);
    return FacebookApiException(
      kind: kind,
      message: _friendly(kind, rawMessage),
      code: code,
      subcode: subcode,
    );
  }

  static FacebookApiErrorKind _classify(
    int? code,
    int? subcode,
    int? statusCode,
  ) {
    if (code == 190) return FacebookApiErrorKind.expiredToken;
    if (code == 200 || code == 10) return FacebookApiErrorKind.permission;
    if (code == 4 || code == 17 || code == 32 || code == 613) {
      return FacebookApiErrorKind.rateLimit;
    }
    if (code == 506 || subcode == 506) return FacebookApiErrorKind.duplicate;
    return FacebookApiErrorKind.unknown;
  }

  /// UI copy per kind; unknown kinds surface the raw Graph message, which
  /// Facebook usually writes readably enough.
  static String _friendly(FacebookApiErrorKind kind, String rawMessage) {
    return switch (kind) {
      FacebookApiErrorKind.expiredToken =>
        'Facebook connection expired. Reconnect your Page in Settings.',
      FacebookApiErrorKind.permission =>
        "The token can't post to this Page. Update it in Settings → Facebook.",
      FacebookApiErrorKind.rateLimit =>
        'Facebook is rate-limiting posts. Wait a moment and try again.',
      FacebookApiErrorKind.duplicate =>
        'An identical post was already published. Edit the text a little, '
            'then publish.',
      _ => rawMessage,
    };
  }
}
