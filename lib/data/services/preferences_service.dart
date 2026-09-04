import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/custom_pill.dart';
import '../../domain/models/hashtag_group.dart';
import '../models/ai_provider.dart';

/// Manages user preferences and secure API key storage.
/// Mirrors Android's PreferencesManager with EncryptedSharedPreferences.
@lazySingleton
class PreferencesService {
  PreferencesService({required this._prefs, required this._secureStorage});

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // === API Keys (secure) ===

  Future<String?> getApiKey(AiProvider provider) async {
    final key = switch (provider) {
      AiProvider.gemini => AppConstants.keyGeminiApiKey,
      AiProvider.groq => AppConstants.keyGroqApiKey,
      AiProvider.openRouter => AppConstants.keyOpenRouterApiKey,
      AiProvider.cerebras => AppConstants.keyCerebrasApiKey,
    };
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<void> setApiKey(AiProvider provider, String value) async {
    final key = switch (provider) {
      AiProvider.gemini => AppConstants.keyGeminiApiKey,
      AiProvider.groq => AppConstants.keyGroqApiKey,
      AiProvider.openRouter => AppConstants.keyOpenRouterApiKey,
      AiProvider.cerebras => AppConstants.keyCerebrasApiKey,
    };
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      try {
        await _secureStorage.deleteAll();
        await _secureStorage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  Future<String?> getTavilyApiKey() async {
    try {
      return await _secureStorage.read(key: AppConstants.keyTavilyApiKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setTavilyApiKey(String value) async {
    try {
      await _secureStorage.write(
        key: AppConstants.keyTavilyApiKey,
        value: value,
      );
    } catch (e) {
      try {
        await _secureStorage.delete(key: AppConstants.keyTavilyApiKey);
        await _secureStorage.write(
          key: AppConstants.keyTavilyApiKey,
          value: value,
        );
      } catch (_) {}
    }
  }

  // === Theme ===

  AppThemeMode get themeMode {
    final value = _prefs.getString(AppConstants.keyThemeMode);
    return AppThemeMode.fromString(value);
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

  List<HashtagGroup> get hashtagGroups {
    final list = _prefs.getStringList('hashtag_groups') ?? [];
    return list.map((e) => HashtagGroup.fromJson(jsonDecode(e))).toList();
  }

  Future<bool> setHashtagGroups(List<HashtagGroup> groups) {
    final list = groups.map((e) => jsonEncode(e.toJson())).toList();
    return _prefs.setStringList('hashtag_groups', list);
  }

  String get defaultHashtags {
    final groups = hashtagGroups;
    for (var g in groups) {
      if (g.isDefault) return g.hashtags;
    }
    return _prefs.getString(AppConstants.keyDefaultHashtags) ?? '';
  }

  Future<bool> setDefaultHashtags(String hashtags) {
    // Legacy fallback write
    return _prefs.setString(AppConstants.keyDefaultHashtags, hashtags);
  }

  bool get autoAppendHashtags =>
      _prefs.getBool(AppConstants.keyAutoAppendHashtags) ?? true;

  Future<bool> setAutoAppendHashtags({required bool enabled}) {
    return _prefs.setBool(AppConstants.keyAutoAppendHashtags, enabled);
  }

  // === Custom Refinement Pills ===

  List<CustomPill> get customPills {
    final list = _prefs.getStringList('custom_refinement_pills') ?? [];
    return list.map((e) => CustomPill.fromJson(jsonDecode(e))).toList();
  }

  Future<bool> setCustomPills(List<CustomPill> pills) {
    final list = pills.map((e) => jsonEncode(e.toJson())).toList();
    return _prefs.setStringList('custom_refinement_pills', list);
  }

  // === Reading Text Size (persistent) ===
  double get readingTextSize =>
      _prefs.getDouble(AppConstants.keyReadingTextSize) ?? 16.0;

  Future<bool> setReadingTextSize(double size) {
    return _prefs.setDouble(
      AppConstants.keyReadingTextSize,
      size.clamp(12.0, 24.0),
    );
  }

  // === Custom Card Branding (persistent) ===

  String get brandName => _prefs.getString('card_brand_name') ?? '';

  Future<bool> setBrandName(String name) {
    return _prefs.setString('card_brand_name', name);
  }

  String get brandHandle => _prefs.getString('card_brand_handle') ?? '';

  Future<bool> setBrandHandle(String handle) {
    return _prefs.setString('card_brand_handle', handle);
  }

  String get watermarkText => _prefs.getString('card_watermark_text') ?? '';

  Future<bool> setWatermarkText(String text) {
    return _prefs.setString('card_watermark_text', text);
  }

  bool get showWatermark => _prefs.getBool('card_show_watermark') ?? false;

  Future<bool> setShowWatermark(bool show) {
    return _prefs.setBool('card_show_watermark', show);
  }

  bool get showBrandFooter => _prefs.getBool('card_show_brand_footer') ?? true;

  Future<bool> setShowBrandFooter(bool show) {
    return _prefs.setBool('card_show_brand_footer', show);
  }

  // === Fan Mode (persistent) ===

  bool get isFanModeEnabled => _prefs.getBool('is_fan_mode_enabled') ?? false;

  Future<bool> setFanModeEnabled(bool enabled) {
    return _prefs.setBool('is_fan_mode_enabled', enabled);
  }

  String get fanClubName => _prefs.getString('fan_club_name') ?? '';

  Future<bool> setFanClubName(String name) {
    return _prefs.setString('fan_club_name', name);
  }

  // === Generation Options Persistence ===

  bool get persistGenerationOptions =>
      _prefs.getBool(AppConstants.keyPersistGenerationOptions) ?? false;

  Future<bool> setPersistGenerationOptions(bool enabled) {
    return _prefs.setBool(AppConstants.keyPersistGenerationOptions, enabled);
  }

  String get lastPromptLength =>
      _prefs.getString(AppConstants.keyLastPromptLength) ?? 'medium';

  Future<bool> setLastPromptLength(String length) {
    return _prefs.setString(AppConstants.keyLastPromptLength, length);
  }

  bool get lastIsResearchMode =>
      _prefs.getBool(AppConstants.keyLastIsResearchMode) ?? false;

  Future<bool> setLastIsResearchMode(bool enabled) {
    return _prefs.setBool(AppConstants.keyLastIsResearchMode, enabled);
  }

  bool get lastKeepStructure =>
      _prefs.getBool(AppConstants.keyLastKeepStructure) ?? false;

  Future<bool> setLastKeepStructure(bool enabled) {
    return _prefs.setBool(AppConstants.keyLastKeepStructure, enabled);
  }
}
