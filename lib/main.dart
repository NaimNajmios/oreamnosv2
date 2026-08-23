import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences before app starts
  final sharedPrefs = await SharedPreferences.getInstance();

  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final preferencesService = PreferencesService(
    prefs: sharedPrefs,
    secureStorage: secureStorage,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: preferencesService),
      ],
      child: const OreamnosApp(),
    ),
  );
}
