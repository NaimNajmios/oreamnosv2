import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/injection.dart';

import 'domain/services/font_preflight.dart';
import 'data/services/notification_service.dart';
import 'data/services/quick_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
