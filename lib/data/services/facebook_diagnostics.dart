import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

/// Redacted, token-free logging for Facebook Graph operations.
///
/// Only the failure taxonomy (`kind`, `code`, `subcode`, `networkIssue`), the
/// action name, an optional Page id, an HTTP status, and the sanitized
/// Meta `error.message` plus `fbtrace_id` are recorded. Tokens, captions,
/// request URLs and response bodies never reach the log.
abstract final class FacebookDiagnostics {
  static const String tag = 'Facebook';
  static const int maxSanitizedLength = 200;

  static LogService? get _log =>
      getIt.isRegistered<LogService>() ? getIt<LogService>() : null;

  /// Records a failed Graph operation. [error] is reduced to a safe taxonomy
  /// before it is written.
  static void failure(
    String action,
    Object error, {
    int? statusCode,
    String? pageId,
  }) {
    final log = _log;
    if (log == null) return;
    log.error(
      '$action failed',
      tag: tag,
      details: _describe(error, statusCode: statusCode, pageId: pageId),
    );
  }

  /// Records a failed Graph operation at WARN level (used for expected
  /// "unavailable for this Page" outcomes that are not bugs).
  static void warning(
    String action,
    Object error, {
    int? statusCode,
    String? pageId,
  }) {
    final log = _log;
    if (log == null) return;
    log.warning(
      '$action failed',
      tag: tag,
      details: _describe(error, statusCode: statusCode, pageId: pageId),
    );
  }

  /// A short user-facing reason from Meta's raw `error.message`, sanitized:
  /// "Meta: ..." or a fallback when Meta sent none.
  static String metaReason(String? graphMessage) {
    final text = sanitizeGraphMessage(graphMessage);
    return text.isEmpty ? 'Meta reports the request failed.' : 'Meta: $text';
  }

  /// Redacts access tokens, `Bearer` values and `access_token=` query values,
  /// collapses whitespace and caps the result at [maxSanitizedLength].
  static String sanitizeGraphMessage(String? message) {
    if (message == null) return '';
    final redacted = message
        .replaceAll(RegExp(r'\bEAA[\w-]+'), 'EAA<redacted>')
        .replaceAll(RegExp(r'Bearer [^\s]+'), 'Bearer <redacted>')
        .replaceAll(RegExp(r'access_token=[^&\s]+'), 'access_token=<redacted>');
    final collapsed = redacted.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= maxSanitizedLength) return collapsed;
    return collapsed.substring(0, maxSanitizedLength).trimRight();
  }

  /// Records a successful write at debug level (no payloads).
  ///
  /// [detail] carries small non-sensitive counters such as `freed=4` for
  /// actions that have no HTTP status. Never pass captions, ids, or paths.
  static void event(
    String action, {
    String? pageId,
    int? statusCode,
    String? detail,
  }) {
    final log = _log;
    if (log == null) return;
    log.debug(
      action,
      tag: tag,
      details: [
        if (pageId != null && pageId.isNotEmpty) 'page=$pageId',
        if (statusCode != null) 'status=$statusCode',
        if (detail != null && detail.isNotEmpty) detail,
      ].join(' '),
    );
  }

  /// Builds the redacted detail string. Public for tests.
  static String describe(Object error, {int? statusCode, String? pageId}) =>
      _describe(error, statusCode: statusCode, pageId: pageId);

  static String _describe(Object error, {int? statusCode, String? pageId}) {
    final parts = <String>[];
    if (error is FacebookApiException) {
      parts.add('kind=${error.kind.name}');
      if (error.code != null) parts.add('code=${error.code}');
      if (error.subcode != null) parts.add('subcode=${error.subcode}');
      if (error.networkIssue != null) {
        parts.add('networkIssue=${error.networkIssue!.name}');
      }
      if (error.traceId != null && error.traceId!.isNotEmpty) {
        parts.add('trace=${error.traceId}');
      }
      final graphMessage = sanitizeGraphMessage(error.graphMessage);
      if (graphMessage.isNotEmpty) {
        parts.add('meta="$graphMessage"');
      }
    } else {
      // Never echo an arbitrary exception message: it may contain a URL,
      // caption, or token. The runtime type is enough to triage.
      parts.add('kind=${error.runtimeType}');
    }
    if (statusCode != null) parts.add('status=$statusCode');
    if (pageId != null && pageId.isNotEmpty) parts.add('page=$pageId');
    return parts.join(' ');
  }
}
