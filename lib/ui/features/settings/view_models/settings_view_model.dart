import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../../../data/models/ai_provider.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/custom_pill.dart';
import '../../../../domain/models/hashtag_group.dart';
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

    state = state.copyWith(
      isInitialized: true,
      themeMode: themeMode,
      selectedProvider: selectedProvider,
      selectedModel: selectedModel,
      toneMode: toneMode,
      defaultHashtags: defaultHashtags,
      hashtagGroups: hashtagGroups,
      autoAppendHashtags: autoAppendHashtags,
      customPills: customPills,
      readingTextSize: readingTextSize,
      tavilyApiKey: tavilyApiKey,
      currentApiKey: currentApiKey,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state.themeMode == mode) return;
    await _preferencesService.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setSelectedProvider(AiProvider provider) async {
    if (state.selectedProvider == provider) return;
    await _preferencesService.setSelectedProvider(provider);
    final model = _preferencesService.getSelectedModel(provider);
    final key = await _preferencesService.getApiKey(provider);
    state = state.copyWith(
      selectedProvider: provider,
      selectedModel: model,
      clearModel: model == null,
      currentApiKey: key,
      clearApiKey: key == null,
    );
  }

  Future<void> setSelectedModel(String modelId) async {
    if (state.selectedModel == modelId) return;
    await _preferencesService.setSelectedModel(state.selectedProvider, modelId);
    state = state.copyWith(selectedModel: modelId);
  }

  Future<void> setApiKey(AiProvider provider, String key) async {
    await _preferencesService.setApiKey(provider, key);
    if (state.selectedProvider == provider) {
      state = state.copyWith(currentApiKey: key);
    }
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

  Future<void> setToneMode(String tone) async {
    if (state.toneMode == tone) return;
    await _preferencesService.setToneMode(tone);
    state = state.copyWith(toneMode: tone);
  }

  Future<void> setDefaultHashtags(String hashtags) async {
    if (state.defaultHashtags == hashtags) return;
    await _preferencesService.setDefaultHashtags(hashtags);
    state = state.copyWith(defaultHashtags: hashtags);
  }

  Future<void> setAutoAppendHashtags(bool enabled) async {
    if (state.autoAppendHashtags == enabled) return;
    await _preferencesService.setAutoAppendHashtags(enabled: enabled);
    state = state.copyWith(autoAppendHashtags: enabled);
  }

  Future<void> addCustomPill(CustomPill pill) async {
    final pills = List<CustomPill>.of(state.customPills)..add(pill);
    await _preferencesService.setCustomPills(pills);
    state = state.copyWith(customPills: pills);
  }

  Future<void> removeCustomPill(CustomPill pill) async {
    final pills = List<CustomPill>.of(state.customPills)
      ..removeWhere(
        (p) => p.label == pill.label && p.instruction == pill.instruction,
      );
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

  Future<void> setReadingTextSize(double size) async {
    final clamped = size.clamp(12.0, 24.0);
    if (state.readingTextSize == clamped) return;
    await _preferencesService.setReadingTextSize(clamped);
    state = state.copyWith(readingTextSize: clamped);
  }
}
