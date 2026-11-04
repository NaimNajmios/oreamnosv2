/// Lightweight bridge so non-Riverpod services (history/comment controllers)
/// can mark the shared Facebook connection expired without importing the UI
/// provider graph (which would create a cycle).
abstract final class FacebookExpirySignal {
  static void Function()? onExpired;

  static void report() => onExpired?.call();
}
