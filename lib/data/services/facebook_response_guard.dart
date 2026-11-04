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
