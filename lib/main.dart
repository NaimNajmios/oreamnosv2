import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/injection.dart';

import 'data/services/notification_service.dart';
import 'data/services/quick_settings_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
