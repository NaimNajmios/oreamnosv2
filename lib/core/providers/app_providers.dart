export 'log_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/ml_kit_vision_extractor.dart';
import '../../data/services/preferences_service.dart';
import '../../data/services/usage_service.dart';
import '../../domain/services/vision_extractor.dart';
import '../network/api_client.dart';
import '../repositories/card_repository.dart';
import '../repositories/content_repository.dart';

// Core DI — Phase A incremental (coexists with provider's MultiProvider)
// These will gradually replace main.dart:35-40 manual wiring.

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override with SharedPreferences instance in ProviderScope');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final storage = ref.watch(secureStorageProvider);
  return PreferencesService(prefs: prefs, secureStorage: storage);
});

final usageServiceProvider = Provider<UsageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UsageService(prefs);
});

final visionExtractorProvider = Provider<IVisionExtractor>((ref) {
  return MLKitVisionExtractor();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final contentRepositoryProvider = Provider((ref) {
  // ignore: avoid_dynamic_calls
  return ContentRepository();
});

final cardRepositoryProvider = Provider((ref) {
  return CardRepository();
});
