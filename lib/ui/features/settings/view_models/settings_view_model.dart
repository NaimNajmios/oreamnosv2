import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../../../data/models/ai_provider.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../data/services/provider_api_service.dart';
import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/custom_pill.dart';
import '../../../../domain/models/hashtag_group.dart';
import '../../../../domain/models/vision_mode.dart';
import 'settings_state.dart';

final settingsViewModelProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(() => SettingsNotifier());

class SettingsNotifier extends Notifier<SettingsState> {
  late final PreferencesService _preferencesService;

  @override
  SettingsState build() {
    _preferencesService = getIt<PreferencesService>();
    _loadState();
    return const SettingsState();
  }

  Future<void> _loadState() async {
    final themeMode = _preferencesService.themeMode;
    final selectedProvider = _preferencesService.selectedProvider;
    final selectedModel = _preferencesService.getSelectedModel(
      selectedProvider,
    );
    final toneMode = _preferencesService.toneMode;
    final defaultHashtags = _preferencesService.defaultHashtags;
    final hashtagGroups = _preferencesService.hashtagGroups;
    final autoAppendHashtags = _preferencesService.autoAppendHashtags;
    final customPills = _preferencesService.customPills;
    final readingTextSize = _preferencesService.readingTextSize;
    final tavilyApiKey = await _preferencesService.getTavilyApiKey();
    final currentApiKey = await _preferencesService.getApiKey(selectedProvider);
    final isFanModeEnabled = _preferencesService.isFanModeEnabled;
    final fanClubName = _preferencesService.fanClubName;
    final persistGenerationOptions =
        _preferencesService.persistGenerationOptions;
    final visionMode = _preferencesService.visionMode;
    final lastTestOk = _preferencesService.getLastTestOk(selectedProvider);
    final lastTestedAt = _preferencesService.getLastTestedAt(selectedProvider);
    state = state.copyWith(
      isInitialized: true,
      themeMode: themeMode,
      selectedProvider: selectedProvider,
      selectedModel: selectedModel,
      lastTestOk: lastTestOk,
      lastTestedAt: lastTestedAt,
      toneMode: toneMode,
      defaultHashtags: defaultHashtags,
      hashtagGroups: hashtagGroups,
      autoAppendHashtags: autoAppendHashtags,
      customPills: customPills,
      readingTextSize: readingTextSize,
      tavilyApiKey: tavilyApiKey,
      currentApiKey: currentApiKey,
      isFanModeEnabled: isFanModeEnabled,
      fanClubName: fanClubName,
      persistGenerationOptions: persistGenerationOptions,
      visionMode: visionMode,
    );
  }

  /// Applies [next] immediately, then persists. A failed write restores the
  /// previous state so the UI never claims a setting was saved when it wasn't.
  Future<bool> _optimistic(
    SettingsState next,
    Future<bool> Function() persist,
  ) async {
    final previous = state;
    state = next;
    try {
      if (await persist()) return true;
    } catch (_) {}
    state = previous;
    return false;
  }

  Future<bool> setThemeMode(AppThemeMode mode) {
    if (state.themeMode == mode) return Future.value(true);
    return _optimistic(
      state.copyWith(themeMode: mode),
      () => _preferencesService.setThemeMode(mode),
    );
  }

  Future<void> setSelectedProvider(AiProvider provider) async {
    if (state.selectedProvider == provider) return;
    await _preferencesService.setSelectedProvider(provider);
    final model = _preferencesService.getSelectedModel(provider);
    final key = await _preferencesService.getApiKey(provider);
    final lastTestOk = _preferencesService.getLastTestOk(provider);
    final lastTestedAt = _preferencesService.getLastTestedAt(provider);
    state = state.copyWith(
      selectedProvider: provider,
      selectedModel: model,
      clearModel: model == null,
      currentApiKey: key,
      clearApiKey: key == null,
      lastTestOk: lastTestOk,
      lastTestedAt: lastTestedAt,
      clearLastTest: lastTestOk == null,
    );
  }

  Future<void> setSelectedModel(String modelId) async {
    if (state.selectedModel == modelId) return;
    final provider = state.selectedProvider;
    await _preferencesService.setSelectedModel(provider, modelId);
    // Model change invalidates the verified flag for this provider.
    await _preferencesService.clearLastTestResult(provider);
    state = state.copyWith(selectedModel: modelId, clearLastTest: true);
  }

  Future<void> setApiKey(AiProvider provider, String key) async {
    await _preferencesService.setApiKey(provider, key);
    // Key change invalidates the verified flag for this provider.
    await _preferencesService.clearLastTestResult(provider);
    if (state.selectedProvider == provider) {
      state = state.copyWith(currentApiKey: key, clearLastTest: true);
    }
  }

  /// Removes a provider key and clears its verification state.
  Future<void> clearApiKey(AiProvider provider) async {
    await _preferencesService.deleteApiKey(provider);
    await _preferencesService.clearLastTestResult(provider);
    if (state.selectedProvider == provider) {
      state = state.copyWith(clearApiKey: true, clearLastTest: true);
    }
  }

  Future<void> clearTavilyApiKey() async {
    await _preferencesService.deleteTavilyApiKey();
    state = state.copyWith(clearTavilyKey: true);
  }

  /// Clears a manual model choice so the provider default is used again.
  Future<void> clearSelectedModel() async {
    final provider = state.selectedProvider;
    await _preferencesService.clearSelectedModel(provider);
    await _preferencesService.clearLastTestResult(provider);
    state = state.copyWith(clearModel: true, clearLastTest: true);
  }

  Future<void> setLastTestResult(bool ok) async {
    final at = DateTime.now();
    await _preferencesService.setLastTestResult(state.selectedProvider, ok, at);
    state = state.copyWith(lastTestOk: ok, lastTestedAt: at);
  }

  /// Verifies the active provider with its stored key and persists the result.
  /// Returns false when no key is configured or the request fails.
  Future<bool> testConnection() async {
    final provider = state.selectedProvider;
    final key = await _preferencesService.getApiKey(provider) ?? '';
    if (key.isEmpty) return false;
    bool ok;
    try {
      ok = await getIt<ProviderApiService>().testConnection(provider, key);
    } catch (_) {
      ok = false;
    }
    await setLastTestResult(ok);
    return ok;
  }

  Future<String?> getApiKeyForProvider(AiProvider provider) async {
    return await _preferencesService.getApiKey(provider);
  }

  Future<void> setTavilyApiKey(String key) async {
    await _preferencesService.setTavilyApiKey(key);
    state = state.copyWith(tavilyApiKey: key);
  }

  Future<String?> getTavilyApiKey() async {
    return await _preferencesService.getTavilyApiKey();
  }

  Future<bool> setToneMode(String tone) {
    if (state.toneMode == tone) return Future.value(true);
    return _optimistic(
      state.copyWith(toneMode: tone),
      () => _preferencesService.setToneMode(tone),
    );
  }

  Future<void> setDefaultHashtags(String hashtags) async {
    if (state.defaultHashtags == hashtags) return;
    await _preferencesService.setDefaultHashtags(hashtags);
    state = state.copyWith(defaultHashtags: hashtags);
  }

  Future<bool> setAutoAppendHashtags(bool enabled) {
    if (state.autoAppendHashtags == enabled) return Future.value(true);
    return _optimistic(
      state.copyWith(autoAppendHashtags: enabled),
      () => _preferencesService.setAutoAppendHashtags(enabled: enabled),
    );
  }

  Future<void> addCustomPill(CustomPill pill) async {
    final pills = List<CustomPill>.of(state.customPills)..add(pill);
    await _preferencesService.setCustomPills(pills);
    state = state.copyWith(customPills: pills);
  }

  Future<void> removeCustomPill(CustomPill pill) async {
    final pills = List<CustomPill>.of(state.customPills)
      ..removeWhere((p) => p.id == pill.id);
    await _preferencesService.setCustomPills(pills);
    state = state.copyWith(customPills: pills);
  }

  Future<void> reorderCustomPills(int oldIndex, int newIndex) async {
    final pills = List<CustomPill>.of(state.customPills);
    if (oldIndex < 0 || oldIndex >= pills.length) {
      return;
    }
    final item = pills.removeAt(oldIndex);
    final targetIndex = newIndex.clamp(0, pills.length);
    pills.insert(targetIndex, item);
    await _preferencesService.setCustomPills(pills);
    state = state.copyWith(customPills: pills);
  }

  Future<void> addHashtagGroup(HashtagGroup group) async {
    final isFirst = state.hashtagGroups.isEmpty;
    final newGroup = isFirst ? group.copyWith(isDefault: true) : group;
    final groups = List<HashtagGroup>.of(state.hashtagGroups)..add(newGroup);
    await _preferencesService.setHashtagGroups(groups);
    if (newGroup.isDefault) {
      state = state.copyWith(
        hashtagGroups: groups,
        defaultHashtags: newGroup.hashtags,
      );
    } else {
      state = state.copyWith(hashtagGroups: groups);
    }
  }

  Future<void> removeHashtagGroup(HashtagGroup group) async {
    final groups = List<HashtagGroup>.of(state.hashtagGroups)
      ..removeWhere((g) => g.id == group.id);
    String defHashtags = state.defaultHashtags;
    if (group.isDefault && groups.isNotEmpty) {
      final newDefault = groups.first.copyWith(isDefault: true);
      groups[0] = newDefault;
      defHashtags = newDefault.hashtags;
    } else if (group.isDefault) {
      defHashtags = '';
    }
    await _preferencesService.setHashtagGroups(groups);
    state = state.copyWith(hashtagGroups: groups, defaultHashtags: defHashtags);
  }

  Future<void> setDefaultHashtagGroup(String id) async {
    String defHashtags = state.defaultHashtags;
    final groups = state.hashtagGroups.map((g) {
      if (g.id == id) {
        defHashtags = g.hashtags;
        return g.copyWith(isDefault: true);
      }
      return g.copyWith(isDefault: false);
    }).toList();
    await _preferencesService.setHashtagGroups(groups);
    state = state.copyWith(hashtagGroups: groups, defaultHashtags: defHashtags);
  }

  Future<bool> setReadingTextSize(double size) {
    final clamped = size.clamp(12.0, 24.0);
    if (state.readingTextSize == clamped) return Future.value(true);
    return _optimistic(
      state.copyWith(readingTextSize: clamped),
      () => _preferencesService.setReadingTextSize(clamped),
    );
  }

  Future<bool> setFanModeEnabled(bool enabled) {
    if (state.isFanModeEnabled == enabled) return Future.value(true);
    return _optimistic(
      state.copyWith(isFanModeEnabled: enabled),
      () => _preferencesService.setFanModeEnabled(enabled),
    );
  }

  Future<bool> setFanClubName(String name) {
    if (state.fanClubName == name) return Future.value(true);
    return _optimistic(
      state.copyWith(fanClubName: name),
      () => _preferencesService.setFanClubName(name),
    );
  }

  Future<bool> setPersistGenerationOptions(bool enabled) {
    if (state.persistGenerationOptions == enabled) return Future.value(true);
    return _optimistic(
      state.copyWith(persistGenerationOptions: enabled),
      () => _preferencesService.setPersistGenerationOptions(enabled),
    );
  }

  Future<bool> setVisionMode(VisionMode mode) {
    if (state.visionMode == mode) return Future.value(true);
    return _optimistic(
      state.copyWith(visionMode: mode),
      () => _preferencesService.setVisionMode(mode),
    );
  }
}
