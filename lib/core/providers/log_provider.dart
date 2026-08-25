import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/data/services/log_service.dart';

/// Riverpod provider for logging.
///
/// Phase 0: wraps the existing singleton so both `LogService()` and
/// `ref.watch(logServiceProvider)` work. Tests can override with
/// `LogService.test()`.
///
/// Example:
/// ```dart
/// final log = ref.read(logServiceProvider);
/// log.info('generated');
/// ```
final logServiceProvider = Provider<ILogService>((ref) {
  // Keep singleton semantics for now to avoid duplicate buffers.
  // Phase A will consider `Provider((ref) => LogService.test())` if isolation needed.
  final service = LogService();
  ref.onDispose(service.dispose);
  return service;
});

// Convenience ChangeNotifier provider for UI that watches logs.
final logNotifierProvider = ChangeNotifierProvider<LogService>((ref) {
  final service = LogService();
  ref.onDispose(service.dispose);
  return service;
});
