import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/injection.dart';

import 'domain/services/font_preflight.dart';
import 'data/services/log_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/quick_settings_service.dart';

/// Funnels both framework and engine errors into the in-app debug log ring.
/// Installed before DI so a failure during startup is still captured, with a
/// debugPrint fallback for the window before [LogService] is registered.
void _installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    _recordUncaughtError(
      'Flutter',
      details.exception,
      details.stack,
      context: details.context?.toString(),
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _recordUncaughtError('Platform', error, stack);
    return true;
  };
}

void _recordUncaughtError(
  String source,
  Object error,
  StackTrace? stack, {
  String? context,
}) {
  // Logging must never mask the original failure or throw from an error
  // handler, hence the broad catch.
  try {
    if (getIt.isRegistered<LogService>()) {
      getIt<LogService>().error(
        'Uncaught $source error',
        error: error,
        stackTrace: stack,
        tag: 'GlobalError',
        details: context,
      );
      return;
    }
  } catch (_) {}
  debugPrint('Uncaught $source error: $error\n$stack');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();

  final missingFonts = await FontPreflight.missingAssets();
  if (missingFonts.isNotEmpty) {
    debugPrint('Card fonts missing from bundle: ${missingFonts.join(', ')}');
  }

  await configureDependencies();

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  try {
    await QuickSettingsService.init();
  } catch (e) {
    debugPrint('QuickSettings init error: $e');
  }

  runApp(const ProviderScope(child: OreamnosApp()));
}
