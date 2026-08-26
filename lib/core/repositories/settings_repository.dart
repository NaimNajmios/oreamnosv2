import '../../data/models/ai_provider.dart';
import '../../data/services/preferences_service.dart';
import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/custom_pill.dart';
import '../../domain/models/hashtag_group.dart';

abstract class ISettingsRepository {
  AppThemeMode get themeMode;
  AiProvider get selectedProvider;
  String? getSelectedModel(AiProvider provider);
  String get toneMode;
  String get defaultHashtags;
  List<HashtagGroup> get hashtagGroups;
  bool get autoAppendHashtags;
  List<CustomPill> get customPills;

  Future<void> setThemeMode(AppThemeMode mode);
  Future<void> setSelectedProvider(AiProvider provider);
  Future<void> setSelectedModel(AiProvider provider, String modelId);
  Future<void> setApiKey(AiProvider provider, String key);
  Future<String?> getApiKey(AiProvider provider);
  Future<void> setToneMode(String tone);
}

class SettingsRepository implements ISettingsRepository {
  final PreferencesService _prefs;
  SettingsRepository(this._prefs);

  @override
  AppThemeMode get themeMode => _prefs.themeMode;
  @override
  AiProvider get selectedProvider => _prefs.selectedProvider;
  @override
  String? getSelectedModel(AiProvider provider) =>
      _prefs.getSelectedModel(provider);
  @override
  String get toneMode => _prefs.toneMode;
  @override
  String get defaultHashtags => _prefs.defaultHashtags;
  @override
  List<HashtagGroup> get hashtagGroups => _prefs.hashtagGroups;
  @override
  bool get autoAppendHashtags => _prefs.autoAppendHashtags;
  @override
  List<CustomPill> get customPills => _prefs.customPills;

  @override
  Future<void> setThemeMode(AppThemeMode mode) => _prefs.setThemeMode(mode);
  @override
  Future<void> setSelectedProvider(AiProvider provider) =>
      _prefs.setSelectedProvider(provider);
  @override
  Future<void> setSelectedModel(AiProvider provider, String modelId) =>
      _prefs.setSelectedModel(provider, modelId);
  @override
  Future<void> setApiKey(AiProvider provider, String key) =>
      _prefs.setApiKey(provider, key);
  @override
  Future<String?> getApiKey(AiProvider provider) => _prefs.getApiKey(provider);
  @override
  Future<void> setToneMode(String tone) => _prefs.setToneMode(tone);
}
