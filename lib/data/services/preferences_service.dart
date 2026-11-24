import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/custom_pill.dart';
import '../../domain/models/hashtag_group.dart';
import '../../domain/models/vision_mode.dart';
import '../models/ai_provider.dart';
import 'facebook_publisher_service.dart';
import 'usage_service.dart';

/// Thrown when the platform secure store rejects a credential write even
/// after a single retry. Callers should surface this instead of claiming the
/// value was saved.
class CredentialStoreException implements Exception {
  const CredentialStoreException(this.operation, this.cause);

  final String operation;
  final Object cause;

  @override
  String toString() => 'CredentialStoreException($operation): $cause';
}

/// Manages user preferences and secure API key storage.
/// Mirrors Android's PreferencesManager with EncryptedSharedPreferences.
@lazySingleton
class PreferencesService {
  PreferencesService({required this._prefs, required this._secureStorage});

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // === API Keys (secure) ===

  static String _keyFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.gemini => AppConstants.keyGeminiApiKey,
      AiProvider.groq => AppConstants.keyGroqApiKey,
      AiProvider.openRouter => AppConstants.keyOpenRouterApiKey,
      AiProvider.cerebras => AppConstants.keyCerebrasApiKey,
    };
  }

  /// Reads a provider key. A transient platform failure is retried once for the
  /// same key only — never a store-wide wipe, which would destroy unrelated
  /// Facebook tokens and other providers' keys.
  Future<String?> getApiKey(AiProvider provider) async {
    final key = _keyFor(provider);
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      try {
        return await _secureStorage.read(key: key);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> setApiKey(AiProvider provider, String value) async {
    final key = _keyFor(provider);
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      try {
        await _secureStorage.write(key: key, value: value);
      } catch (retryError) {
        throw CredentialStoreException('write', retryError);
      }
    }
  }

  Future<void> deleteApiKey(AiProvider provider) async {
    final key = _keyFor(provider);
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      try {
        await _secureStorage.delete(key: key);
      } catch (retryError) {
        throw CredentialStoreException('delete', retryError);
      }
    }
  }

  Future<String?> getTavilyApiKey() async {
    try {
      return await _secureStorage.read(key: AppConstants.keyTavilyApiKey);
    } catch (_) {
      try {
        return await _secureStorage.read(key: AppConstants.keyTavilyApiKey);
      } catch (_) {
        return null;
      }
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
        await _secureStorage.write(
          key: AppConstants.keyTavilyApiKey,
          value: value,
        );
      } catch (retryError) {
        throw CredentialStoreException('write', retryError);
      }
    }
  }

  Future<void> deleteTavilyApiKey() async {
    try {
      await _secureStorage.delete(key: AppConstants.keyTavilyApiKey);
    } catch (e) {
      try {
        await _secureStorage.delete(key: AppConstants.keyTavilyApiKey);
      } catch (retryError) {
        throw CredentialStoreException('delete', retryError);
      }
    }
  }

  // === Facebook Page connection ===

  /// Token for the active Page (falls back to the legacy single key during
  /// migration).
  Future<String?> getFacebookPageToken() async {
    final active = facebookActivePageId;
    if (active != null && active.isNotEmpty) {
      final token = await getFacebookPageTokenFor(active);
      if (token != null && token.isNotEmpty) return token;
    }
    try {
      return await _secureStorage.read(key: AppConstants.keyFacebookPageToken);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getFacebookPageTokenFor(String pageId) async {
    if (pageId.isEmpty) return null;
    try {
      return await _secureStorage.read(
        key: AppConstants.facebookPageTokenKey(pageId),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setFacebookPageTokenFor(String pageId, String value) async {
    if (pageId.isEmpty) return;
    final key = AppConstants.facebookPageTokenKey(pageId);
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      try {
        await _secureStorage.delete(key: key);
        await _secureStorage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  /// Granted scope names for [pageId], captured during connect.
  List<String> facebookGrantedScopesFor(String pageId) {
    if (pageId.isEmpty) return const [];
    final raw = _prefs.getString(
      '${AppConstants.keyFacebookGrantedScopesPrefix}$pageId',
    );
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toList();
    } catch (_) {}
    return const [];
  }

  Future<void> setFacebookGrantedScopes(
    String pageId,
    List<String> scopes,
  ) async {
    if (pageId.isEmpty) return;
    final names =
        scopes.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList()
          ..sort();
    await _prefs.setString(
      '${AppConstants.keyFacebookGrantedScopesPrefix}$pageId',
      jsonEncode(names),
    );
  }

  Future<void> deleteFacebookPageToken(String pageId) async {
    if (pageId.isEmpty) return;
    try {
      await _secureStorage.delete(
        key: AppConstants.facebookPageTokenKey(pageId),
      );
    } catch (_) {}
  }

  Future<void> setFacebookPageToken(String value) async {
    try {
      await _secureStorage.write(
        key: AppConstants.keyFacebookPageToken,
        value: value,
      );
    } catch (e) {
      try {
        await _secureStorage.delete(key: AppConstants.keyFacebookPageToken);
        await _secureStorage.write(
          key: AppConstants.keyFacebookPageToken,
          value: value,
        );
      } catch (_) {}
    }
  }

  // === Multi-page storage (prefs; tokens stay in secure storage) ===

  List<FacebookPage> get facebookPages {
    final raw = _prefs.getString(AppConstants.keyFacebookPages);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .where((e) => (e['id'] as String? ?? '').isNotEmpty)
          .map(
            (e) => FacebookPage(
              id: e['id'] as String,
              name: e['name'] as String? ?? '',
              pictureUrl: e['pictureUrl'] as String? ?? '',
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> setFacebookPages(List<FacebookPage> pages) async {
    await _prefs.setString(
      AppConstants.keyFacebookPages,
      jsonEncode([
        for (final page in pages)
          {'id': page.id, 'name': page.name, 'pictureUrl': page.pictureUrl},
      ]),
    );
  }

  String? get facebookActivePageId =>
      _prefs.getString(AppConstants.keyFacebookActivePage);

  Future<void> setFacebookActivePageId(String pageId) async {
    await _prefs.setString(AppConstants.keyFacebookActivePage, pageId);
  }

  Future<void> clearFacebookActivePage() async {
    await _prefs.remove(AppConstants.keyFacebookActivePage);
  }

  /// Upserts a page in the list (identity only, never the token).
  Future<void> upsertFacebookPage(FacebookPage page) async {
    final pages = [...facebookPages];
    final index = pages.indexWhere((p) => p.id == page.id);
    if (index < 0) {
      pages.add(page);
    } else {
      pages[index] = page;
    }
    await setFacebookPages(pages);
  }

  /// Removes one Page's token + entry. Promotes the next page as active and
  /// leaves every other Page untouched.
  Future<void> disconnectFacebookPage(String pageId) async {
    await deleteFacebookPageToken(pageId);
    final pages = facebookPages.where((p) => p.id != pageId).toList();
    await setFacebookPages(pages);
    if (facebookActivePageId == pageId) {
      if (pages.isEmpty) {
        await clearFacebookActivePage();
        await _prefs.remove(AppConstants.keyFacebookPageId);
        await _prefs.remove(AppConstants.keyFacebookPageName);
        await _prefs.remove(AppConstants.keyFacebookPagePicture);
      } else {
        final next = pages.first;
        await setFacebookActivePageId(next.id);
        await setFacebookPageId(next.id);
        await setFacebookPageName(next.name);
        await setFacebookPagePicture(next.pictureUrl);
      }
    }
  }

  /// Full disconnect: every per-page token, Page entries, history, drafts.
  Future<void> disconnectFacebook() async {
    for (final page in facebookPages) {
      await deleteFacebookPageToken(page.id);
    }
    try {
      await _secureStorage.delete(key: AppConstants.keyFacebookPageToken);
    } catch (_) {}
    await _prefs.remove(AppConstants.keyFacebookPages);
    await _prefs.remove(AppConstants.keyFacebookActivePage);
    await _prefs.remove(AppConstants.keyFacebookPageId);
    await _prefs.remove(AppConstants.keyFacebookPageName);
    await _prefs.remove(AppConstants.keyFacebookPagePicture);
    await _prefs.remove(AppConstants.keyFacebookHistory);
    await _prefs.remove(AppConstants.keyFacebookDraft);
    await _prefs.remove(AppConstants.keyFacebookDrafts);
    await _prefs.remove(AppConstants.keyFacebookActiveDraft);
  }

  /// Idempotent v11 → v12 migration: the legacy single token moves under
  /// `facebook_page_token_<id>` and becomes the first Page entry.
  Future<void> migrateLegacyFacebookPage() async {
    if (_prefs.containsKey(AppConstants.keyFacebookPages)) return;
    final legacyId = facebookPageId;
    if (legacyId == null || legacyId.isEmpty) return;
    String? legacyToken;
    try {
      legacyToken = await _secureStorage.read(
        key: AppConstants.keyFacebookPageToken,
      );
    } catch (_) {}
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await setFacebookPageTokenFor(legacyId, legacyToken);
    }
    final page = FacebookPage(
      id: legacyId,
      name: facebookPageName ?? '',
      pictureUrl: facebookPagePicture ?? '',
    );
    await setFacebookPages([page]);
    await setFacebookActivePageId(legacyId);
    // Keep legacy identity keys readable for one release; migration is
    // guarded by `keyFacebookPages`, so they are never re-applied.
  }

  // === Facebook Page identity (prefs) ===

  String? get facebookPageId =>
      _prefs.getString(AppConstants.keyFacebookPageId);

  Future<bool> setFacebookPageId(String value) {
    return _prefs.setString(AppConstants.keyFacebookPageId, value);
  }

  String? get facebookPageName =>
      _prefs.getString(AppConstants.keyFacebookPageName);

  Future<bool> setFacebookPageName(String value) {
    return _prefs.setString(AppConstants.keyFacebookPageName, value);
  }

  String? get facebookPagePicture =>
      _prefs.getString(AppConstants.keyFacebookPagePicture);

  Future<bool> setFacebookPagePicture(String value) {
    return _prefs.setString(AppConstants.keyFacebookPagePicture, value);
  }

  // === Facebook compose draft (autosave) ===

  String? get facebookDraftJson =>
      _prefs.getString(AppConstants.keyFacebookDraft);

  Future<bool> setFacebookDraftJson(String value) {
    return _prefs.setString(AppConstants.keyFacebookDraft, value);
  }

  Future<bool> clearFacebookDraft() {
    return _prefs.remove(AppConstants.keyFacebookDraft);
  }

  // === Facebook maintenance throttles ===

  DateTime? get lastFacebookSweep =>
      _readMillis(AppConstants.keyFacebookLastSweep);

  Future<void> setLastFacebookSweep(DateTime at) => _prefs.setInt(
    AppConstants.keyFacebookLastSweep,
    at.millisecondsSinceEpoch,
  );

  DateTime? get lastFacebookReconcile =>
      _readMillis(AppConstants.keyFacebookLastReconcile);

  Future<void> setLastFacebookReconcile(DateTime at) => _prefs.setInt(
    AppConstants.keyFacebookLastReconcile,
    at.millisecondsSinceEpoch,
  );

  /// Last range selected on the Performance surface (7 / 28 / 90).
  int get facebookPerformanceDays {
    final value = _prefs.getInt(AppConstants.keyFacebookPerformanceDays);
    return value == null || (value != 7 && value != 28 && value != 90)
        ? 28
        : value;
  }

  Future<void> setFacebookPerformanceDays(int days) =>
      _prefs.setInt(AppConstants.keyFacebookPerformanceDays, days);

  /// Whether "Show estimated earnings" is enabled on the Publish tab
  /// (default off: earnings estimates can be misleading without Content
  /// Monetization enrollment).
  bool get facebookMonetizationEnabled =>
      _prefs.getBool(AppConstants.keyFacebookMonetizationEnabled) ?? false;

  Future<void> setFacebookMonetizationEnabled(bool enabled) =>
      _prefs.setBool(AppConstants.keyFacebookMonetizationEnabled, enabled);

  /// When a monetization fetch found the Page is not enrolled (Meta 400 /
  /// code 100): don't request again for 24 hours.
  DateTime? get facebookMonetizationUnavailableUntil =>
      _readMillis(AppConstants.keyFacebookMonetizationUnavailableUntil);

  Future<void> setFacebookMonetizationUnavailableUntil(DateTime at) =>
      _prefs.setInt(
        AppConstants.keyFacebookMonetizationUnavailableUntil,
        at.millisecondsSinceEpoch,
      );

  Future<void> clearFacebookMonetizationUnavailable() =>
      _prefs.remove(AppConstants.keyFacebookMonetizationUnavailableUntil);

  /// Persisted Usage range filter. Only 0 (all time), 7, 30 and 90 are valid.
  int get usageRangeDays {
    final value = _prefs.getInt(AppConstants.keyUsageRangeDays);
    return value == 7 || value == 30 || value == 90 ? value! : 0;
  }

  Future<bool> setUsageRangeDays(int days) {
    final safe = days == 7 || days == 30 || days == 90 ? days : 0;
    return _prefs.setInt(AppConstants.keyUsageRangeDays, safe);
  }

  /// Persisted provider filter; `all` means no provider restriction.
  String get usageProviderFilter {
    final value = _prefs.getString(AppConstants.keyUsageProviderFilter);
    if (value == null || value.trim().isEmpty) return 'all';
    return value.toLowerCase();
  }

  Future<bool> setUsageProviderFilter(String providerId) {
    final safe = providerId.trim().isEmpty
        ? 'all'
        : providerId.trim().toLowerCase();
    return _prefs.setString(AppConstants.keyUsageProviderFilter, safe);
  }

  /// User-adjustable `UsageService` ring size; clamped to the valid range
  /// so a corrupted pref falls back to the default instead of lying.
  int get usageLogMaxSize {
    final value = _prefs.getInt(AppConstants.keyUsageLogMaxSize);
    if (value == null ||
        value < UsageService.minMaxLogs ||
        value > UsageService.maxMaxLogs) {
      return UsageService.defaultMaxLogs;
    }
    return value;
  }

  Future<bool> setUsageLogMaxSize(int size) {
    final safe = size
        .clamp(UsageService.minMaxLogs, UsageService.maxMaxLogs)
        .toInt();
    return _prefs.setInt(AppConstants.keyUsageLogMaxSize, safe);
  }

  DateTime? _readMillis(String key) {
    final value = _prefs.getInt(key);
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
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

  Future<bool> clearSelectedModel(AiProvider provider) {
    return _prefs.remove('model_${provider.name}');
  }

  // === Connection Test Result (per provider, persistent) ===

  bool? getLastTestOk(AiProvider provider) {
    final key = '${AppConstants.keyLastTestOkPrefix}${provider.name}';
    if (!_prefs.containsKey(key)) return null;
    return _prefs.getBool(key);
  }

  DateTime? getLastTestedAt(AiProvider provider) {
    final key = '${AppConstants.keyLastTestedAtPrefix}${provider.name}';
    final millis = _prefs.getInt(key);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastTestResult(
    AiProvider provider,
    bool ok,
    DateTime at,
  ) async {
    await _prefs.setBool(
      '${AppConstants.keyLastTestOkPrefix}${provider.name}',
      ok,
    );
    await _prefs.setInt(
      '${AppConstants.keyLastTestedAtPrefix}${provider.name}',
      at.millisecondsSinceEpoch,
    );
  }

  Future<void> clearLastTestResult(AiProvider provider) async {
    await _prefs.remove('${AppConstants.keyLastTestOkPrefix}${provider.name}');
    await _prefs.remove(
      '${AppConstants.keyLastTestedAtPrefix}${provider.name}',
    );
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

  // === Home-screen widget ===

  /// Whether the next post's caption is mirrored to the home screen. Defaults
  /// to `false`; the Page name, time and counts stay visible either way.
  bool get showWidgetSnippet =>
      _prefs.getBool(AppConstants.keyShowWidgetSnippet) ?? false;

  Future<bool> setShowWidgetSnippet(bool show) {
    return _prefs.setBool(AppConstants.keyShowWidgetSnippet, show);
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

  bool get lastUppercaseTitle =>
      _prefs.getBool(AppConstants.keyLastUppercaseTitle) ?? false;

  Future<bool> setLastUppercaseTitle(bool enabled) {
    return _prefs.setBool(AppConstants.keyLastUppercaseTitle, enabled);
  }

  // === Vision Extraction Mode (Auto cloud chain vs on-device only) ===

  VisionMode get visionMode =>
      VisionMode.fromString(_prefs.getString('vision_mode'));

  Future<bool> setVisionMode(VisionMode mode) {
    return _prefs.setString('vision_mode', mode.name);
  }

  // === Update check ===

  /// When the last successful GitHub release lookup happened.
  DateTime? get updateLastCheck {
    final millis = _prefs.getInt(AppConstants.keyUpdateLastCheck);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<bool> setUpdateLastCheck(DateTime at) {
    return _prefs.setInt(
      AppConstants.keyUpdateLastCheck,
      at.millisecondsSinceEpoch,
    );
  }

  /// Tag the user asked not to be reminded about on automatic checks.
  String? get updateSkippedTag =>
      _prefs.getString(AppConstants.keyUpdateSkippedTag);

  Future<bool> setUpdateSkippedTag(String tag) {
    return _prefs.setString(AppConstants.keyUpdateSkippedTag, tag);
  }

  Future<bool> clearUpdateSkippedTag() {
    return _prefs.remove(AppConstants.keyUpdateSkippedTag);
  }

  // === Settings snapshot (export/import) ===

  /// Snapshot of every shared preference, suitable for [jsonEncode].
  /// Secure-storage API keys are not included — they live in the credential
  /// store.
  Future<Map<String, Object?>> exportSettings() async {
    final map = <String, Object?>{};
    for (final key in _prefs.getKeys()) {
      final value = _prefs.get(key);
      if (value != null) map[key] = value;
    }
    return map;
  }

  /// Applies an exported snapshot (see [exportSettings]) through the typed
  /// setters. Keys with missing or wrongly-typed values are skipped.
  Future<void> importSettings(Map<String, Object?> exported) async {
    final themeName = exported[AppConstants.keyThemeMode];
    if (themeName is String) {
      final mode = AppThemeMode.values
          .where((m) => m.name == themeName)
          .firstOrNull;
      if (mode != null) await setThemeMode(mode);
    }
    final tone = exported[AppConstants.keyToneMode];
    if (tone is String) await setToneMode(tone);
    final vision = exported['vision_mode'];
    if (vision is String) await setVisionMode(VisionMode.fromString(vision));
    final readingSize = exported[AppConstants.keyReadingTextSize];
    if (readingSize is num) {
      await setReadingTextSize(readingSize.toDouble());
    }
    final persist = exported[AppConstants.keyPersistGenerationOptions];
    if (persist is bool) await setPersistGenerationOptions(persist);
    final showSnippet = exported[AppConstants.keyShowWidgetSnippet];
    if (showSnippet is bool) await setShowWidgetSnippet(showSnippet);
    final autoAppend = exported[AppConstants.keyAutoAppendHashtags];
    if (autoAppend is bool) {
      await setAutoAppendHashtags(enabled: autoAppend);
    }
    final fanMode = exported['is_fan_mode_enabled'];
    if (fanMode is bool) await setFanModeEnabled(fanMode);
    final fanName = exported['fan_club_name'];
    if (fanName is String) await setFanClubName(fanName);
    final rangeDays = exported[AppConstants.keyUsageRangeDays];
    if (rangeDays is int) await setUsageRangeDays(rangeDays);
    final providerFilter = exported[AppConstants.keyUsageProviderFilter];
    if (providerFilter is String) {
      await setUsageProviderFilter(providerFilter);
    }
  }
}
