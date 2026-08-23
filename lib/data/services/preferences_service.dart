import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../domain/models/app_theme_mode.dart';
import '../models/ai_provider.dart';

/// Manages user preferences and secure API key storage.
/// Mirrors Android's PreferencesManager with EncryptedSharedPreferences.
class PreferencesService {
  PreferencesService({
    required this._prefs,
    required this._secureStorage,
  });

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // === API Keys (secure) ===

  Future<String?> getApiKey(AiProvider provider) {
    final key = switch (provider) {
      AiProvider.gemini => AppConstants.keyGeminiApiKey,
      AiProvider.groq => AppConstants.keyGroqApiKey,
      AiProvider.openRouter => AppConstants.keyOpenRouterApiKey,
      AiProvider.cerebras => AppConstants.keyCerebrasApiKey,
    };
    return _secureStorage.read(key: key);
  }

  Future<void> setApiKey(AiProvider provider, String value) {
    final key = switch (provider) {
      AiProvider.gemini => AppConstants.keyGeminiApiKey,
      AiProvider.groq => AppConstants.keyGroqApiKey,
      AiProvider.openRouter => AppConstants.keyOpenRouterApiKey,
      AiProvider.cerebras => AppConstants.keyCerebrasApiKey,
    };
    return _secureStorage.write(key: key, value: value);
  }

  // === Theme ===

  AppThemeMode get themeMode {
    final value = _prefs.getString(AppConstants.keyThemeMode);
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<bool> setThemeMode(AppThemeMode mode) {
    return _prefs.setString(AppConstants.keyThemeMode, mode.name);
  }

  // === Selected Provider ===

  AiProvider get selectedProvider {
    final value = _prefs.getString(AppConstants.keySelectedProvider);
    return AiProvider.values.firstWhere(
      (p) => p.name == value,
      orElse: () => AiProvider.gemini,
    );
  }

  Future<bool> setSelectedProvider(AiProvider provider) {
    return _prefs.setString(AppConstants.keySelectedProvider, provider.name);
  }

  // === Selected Model Per Provider ===
  String? getSelectedModel(AiProvider provider) {
    return _prefs.getString('model_${provider.name}');
  }

  Future<bool> setSelectedModel(AiProvider provider, String modelId) {
    return _prefs.setString('model_${provider.name}', modelId);
  }

  // === Tone ===

  String get toneMode => _prefs.getString(AppConstants.keyToneMode) ?? 'formal';

  Future<bool> setToneMode(String tone) {
    return _prefs.setString(AppConstants.keyToneMode, tone);
  }

  // === Hashtags ===

  String get defaultHashtags =>
      _prefs.getString(AppConstants.keyDefaultHashtags) ?? '';

  Future<bool> setDefaultHashtags(String hashtags) {
    return _prefs.setString(AppConstants.keyDefaultHashtags, hashtags);
  }

  bool get autoAppendHashtags =>
      _prefs.getBool(AppConstants.keyAutoAppendHashtags) ?? true;

  Future<bool> setAutoAppendHashtags({required bool enabled}) {
    return _prefs.setBool(AppConstants.keyAutoAppendHashtags, enabled);
  }

  // === Custom Refinement Pills ===
  
  List<String> get customPills =>
      _prefs.getStringList('custom_refinement_pills') ?? [];

  Future<bool> setCustomPills(List<String> pills) {
    return _prefs.setStringList('custom_refinement_pills', pills);
  }
}
