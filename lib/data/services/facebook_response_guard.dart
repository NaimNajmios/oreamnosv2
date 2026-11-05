import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/models/facebook_api_exception.dart';

/// Helpers for turning a 200 response that is not the expected JSON object
/// into a useful, non-network error. Never include the full body or token.
String facebookUnexpectedResponseMessage(Object? data) {
  final raw = data is String ? data.toLowerCase() : '';
  if (raw.contains('<html') ||
      raw.contains('<!doctype') ||
      raw.contains('captive') ||
      raw.contains('blocked') ||
      raw.contains('proxy')) {
    return 'Facebook returned a web page instead of JSON. Check VPN, proxy '
        'or captive-portal login.';
  }
  return 'Facebook returned an unexpected response. Re-paste the token or '
      'try again.';
}

Map<String, dynamic>? facebookObjectOrNull(Object? data) {
  if (data is Map) return data.cast<String, dynamic>();
  if (data is String) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
  }
  return null;
}

Map<String, dynamic> facebookRequireObject(
  Object? data, {
  required String action,
}) {
  final map = facebookObjectOrNull(data);
  assert(() {
    debugPrint('[FB] $action response data=${data.runtimeType}');
    return true;
  }());
  if (map == null) {
    throw FacebookApiException(
      kind: FacebookApiErrorKind.unexpectedResponse,
      message: facebookUnexpectedResponseMessage(data),
    );
  }
  return map;
}
