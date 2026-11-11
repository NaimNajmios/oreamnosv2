import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

/// Redacted, token-free logging for Facebook Graph operations.
///
/// Only the failure taxonomy (`kind`, `code`, `subcode`, `networkIssue`), the
/// action name, an optional Page id, and an HTTP status are recorded. Tokens,
/// captions, request URLs, response bodies, and arbitrary exception messages
/// never reach the log.
abstract final class FacebookDiagnostics {
  static const String tag = 'Facebook';

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

  /// Records a successful write at debug level (no payloads).
  static void event(String action, {String? pageId, int? statusCode}) {
    final log = _log;
    if (log == null) return;
    log.debug(
      action,
      tag: tag,
      details: [
        if (pageId != null && pageId.isNotEmpty) 'page=$pageId',
        if (statusCode != null) 'status=$statusCode',
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
