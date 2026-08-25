import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ai_provider.dart';
import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/custom_pill.dart';
import '../../domain/models/hashtag_group.dart';
import 'app_providers.dart';

class SettingsState {
  final bool isInitialized;
  final AppThemeMode themeMode;
  final AiProvider selectedProvider;
  final String? selectedModel;
  final String toneMode;
  final String defaultHashtags;
  final List<HashtagGroup> hashtagGroups;
  final bool autoAppendHashtags;
  final List<CustomPill> customPills;
  final String? currentApiKey;

  const SettingsState({
    this.isInitialized = false,
    this.themeMode = AppThemeMode.system,
    this.selectedProvider = AiProvider.gemini,
    this.selectedModel,
    this.toneMode = 'formal',
    this.defaultHashtags = '',
    this.hashtagGroups = const [],
    this.autoAppendHashtags = true,
    this.customPills = const [],
    this.currentApiKey,
  });

  SettingsState copyWith({
    bool? isInitialized,
    AppThemeMode? themeMode,
    AiProvider? selectedProvider,
    String? selectedModel,
    String? toneMode,
    String? defaultHashtags,
    List<HashtagGroup>? hashtagGroups,
    bool? autoAppendHashtags,
    List<CustomPill>? customPills,
    String? currentApiKey,
  }) {
    return SettingsState(
      isInitialized: isInitialized ?? this.isInitialized,
      themeMode: themeMode ?? this.themeMode,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModel: selectedModel ?? this.selectedModel,
      toneMode: toneMode ?? this.toneMode,
      defaultHashtags: defaultHashtags ?? this.defaultHashtags,
      hashtagGroups: hashtagGroups ?? this.hashtagGroups,
      autoAppendHashtags: autoAppendHashtags ?? this.autoAppendHashtags,
      customPills: customPills ?? this.customPills,
      currentApiKey: currentApiKey ?? this.currentApiKey,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Async init — load from PreferencesService synchronously where possible
    final prefs = ref.watch(preferencesServiceProvider);
    // Kick off async load without blocking build
    Future.microtask(_loadState);
    return SettingsState(
      themeMode: prefs.themeMode,
      selectedProvider: prefs.selectedProvider,
      selectedModel: prefs.getSelectedModel(prefs.selectedProvider),
      toneMode: prefs.toneMode,
      defaultHashtags: prefs.defaultHashtags,
      hashtagGroups: prefs.hashtagGroups,
      autoAppendHashtags: prefs.autoAppendHashtags,
      customPills: prefs.customPills,
    );
  }

  Future<void> _loadState() async {
    final prefs = ref.read(preferencesServiceProvider);
    final provider = prefs.selectedProvider;
    final apiKey = await prefs.getApiKey(provider);
    state = state.copyWith(
      isInitialized: true,
      currentApiKey: apiKey,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state.themeMode == mode) return;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setSelectedProvider(AiProvider provider) async {
    if (state.selectedProvider == provider) return;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setSelectedProvider(provider);
    final model = prefs.getSelectedModel(provider);
    final apiKey = await prefs.getApiKey(provider);
    state = state.copyWith(
      selectedProvider: provider,
      selectedModel: model,
      currentApiKey: apiKey,
    );
  }

  Future<void> setSelectedModel(String modelId) async {
    if (state.selectedModel == modelId) return;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setSelectedModel(state.selectedProvider, modelId);
    state = state.copyWith(selectedModel: modelId);
  }

  Future<void> setApiKey(AiProvider provider, String key) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setApiKey(provider, key);
    if (state.selectedProvider == provider) {
      state = state.copyWith(currentApiKey: key);
    }
  }

  Future<String?> getApiKeyForProvider(AiProvider provider) async {
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.getApiKey(provider);
  }

  Future<void> setToneMode(String tone) async {
    if (state.toneMode == tone) return;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setToneMode(tone);
    state = state.copyWith(toneMode: tone);
  }

  Future<void> setDefaultHashtags(String hashtags) async {
    if (state.defaultHashtags == hashtags) return;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setDefaultHashtags(hashtags);
    state = state.copyWith(defaultHashtags: hashtags);
  }

  Future<void> setAutoAppendHashtags(bool enabled) async {
    if (state.autoAppendHashtags == enabled) return;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setAutoAppendHashtags(enabled: enabled);
    state = state.copyWith(autoAppendHashtags: enabled);
  }

  Future<void> addCustomPill(CustomPill pill) async {
    final updated = List<CustomPill>.of(state.customPills)..add(pill);
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setCustomPills(updated);
    state = state.copyWith(customPills: updated);
  }

  Future<void> removeCustomPill(CustomPill pill) async {
    final updated = List<CustomPill>.of(state.customPills)
      ..removeWhere((p) => p.label == pill.label && p.instruction == pill.instruction);
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setCustomPills(updated);
    state = state.copyWith(customPills: updated);
  }

  Future<void> addHashtagGroup(HashtagGroup group) async {
    final isFirst = state.hashtagGroups.isEmpty;
    final newGroup = isFirst ? group.copyWith(isDefault: true) : group;
    final updated = List<HashtagGroup>.of(state.hashtagGroups)..add(newGroup);
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setHashtagGroups(updated);
    state = state.copyWith(
      hashtagGroups: updated,
      defaultHashtags: newGroup.isDefault ? newGroup.hashtags : state.defaultHashtags,
    );
  }

  Future<void> removeHashtagGroup(HashtagGroup group) async {
    final updated = List<HashtagGroup>.of(state.hashtagGroups)..removeWhere((g) => g.id == group.id);
    String newHashtags = state.defaultHashtags;
    if (group.isDefault && updated.isNotEmpty) {
      final def = updated.first.copyWith(isDefault: true);
      updated[0] = def;
      newHashtags = def.hashtags;
    } else if (group.isDefault) {
      newHashtags = '';
    }
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setHashtagGroups(updated);
    state = state.copyWith(hashtagGroups: updated, defaultHashtags: newHashtags);
  }

  Future<void> setDefaultHashtagGroup(String id) async {
    String newHashtags = state.defaultHashtags;
    final updated = state.hashtagGroups.map((g) {
      if (g.id == id) {
        newHashtags = g.hashtags;
        return g.copyWith(isDefault: true);
      }
      return g.copyWith(isDefault: false);
    }).toList();
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setHashtagGroups(updated);
    state = state.copyWith(hashtagGroups: updated, defaultHashtags: newHashtags);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

// Convenience selectors for incremental migration
final themeModeProvider = Provider<AppThemeMode>((ref) => ref.watch(settingsProvider).themeMode);
final selectedProviderProvider = Provider<AiProvider>((ref) => ref.watch(settingsProvider).selectedProvider);
