import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/core/di/injection.dart';

import '../../../../data/models/ai_provider.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/custom_pill.dart';
import '../../../../domain/models/hashtag_group.dart';

final settingsViewModelProvider = ChangeNotifierProvider<SettingsViewModel>(
  (ref) => SettingsViewModel(ref),
);

class SettingsViewModel extends ChangeNotifier {
  late final PreferencesService _preferencesService;

  final Ref ref;
  SettingsViewModel(this.ref) {
    _preferencesService = getIt<PreferencesService>();
    _loadState();
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late AppThemeMode _themeMode;
  AppThemeMode get themeMode => _themeMode;

  late AiProvider _selectedProvider;
  AiProvider get selectedProvider => _selectedProvider;

  String? _selectedModel;
  String? get selectedModel => _selectedModel;

  late String _toneMode;
  String get toneMode => _toneMode;

  late String _defaultHashtags;
  String get defaultHashtags => _defaultHashtags;

  late List<HashtagGroup> _hashtagGroups;
  List<HashtagGroup> get hashtagGroups => _hashtagGroups;

  late bool _autoAppendHashtags;
  bool get autoAppendHashtags => _autoAppendHashtags;

  late List<CustomPill> _customPills;
  List<CustomPill> get customPills => _customPills;

  late double _readingTextSize;
  double get readingTextSize => _readingTextSize;

  String? _currentApiKey;
  String? get currentApiKey => _currentApiKey;

  Future<void> _loadState() async {
    _themeMode = _preferencesService.themeMode;
    _selectedProvider = _preferencesService.selectedProvider;
    _selectedModel = _preferencesService.getSelectedModel(_selectedProvider);
    _toneMode = _preferencesService.toneMode;
    _defaultHashtags = _preferencesService.defaultHashtags;
    _hashtagGroups = _preferencesService.hashtagGroups;
    _autoAppendHashtags = _preferencesService.autoAppendHashtags;
    _customPills = _preferencesService.customPills;
    _readingTextSize = _preferencesService.readingTextSize;

    await _loadApiKey(_selectedProvider);

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadApiKey(AiProvider provider) async {
    _currentApiKey = await _preferencesService.getApiKey(provider);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    await _preferencesService.setThemeMode(mode);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setSelectedProvider(AiProvider provider) async {
    if (_selectedProvider == provider) return;
    await _preferencesService.setSelectedProvider(provider);
    _selectedProvider = provider;
    _selectedModel = _preferencesService.getSelectedModel(provider);
    await _loadApiKey(provider);
    notifyListeners();
  }

  Future<void> setSelectedModel(String modelId) async {
    if (_selectedModel == modelId) return;
    await _preferencesService.setSelectedModel(_selectedProvider, modelId);
    _selectedModel = modelId;
    notifyListeners();
  }

  Future<void> setApiKey(AiProvider provider, String key) async {
    await _preferencesService.setApiKey(provider, key);
    if (_selectedProvider == provider) {
      _currentApiKey = key;
      notifyListeners();
    }
  }

  Future<String?> getApiKeyForProvider(AiProvider provider) async {
    return await _preferencesService.getApiKey(provider);
  }

  Future<void> setToneMode(String tone) async {
    if (_toneMode == tone) return;
    await _preferencesService.setToneMode(tone);
    _toneMode = tone;
    notifyListeners();
  }

  Future<void> setDefaultHashtags(String hashtags) async {
    if (_defaultHashtags == hashtags) return;
    await _preferencesService.setDefaultHashtags(hashtags);
    _defaultHashtags = hashtags;
    notifyListeners();
  }

  Future<void> setAutoAppendHashtags(bool enabled) async {
    if (_autoAppendHashtags == enabled) return;
    await _preferencesService.setAutoAppendHashtags(enabled: enabled);
    _autoAppendHashtags = enabled;
    notifyListeners();
  }

  Future<void> addCustomPill(CustomPill pill) async {
    _customPills = List.of(_customPills)..add(pill);
    await _preferencesService.setCustomPills(_customPills);
    notifyListeners();
  }

  Future<void> removeCustomPill(CustomPill pill) async {
    _customPills = List.of(_customPills)
      ..removeWhere(
        (p) => p.label == pill.label && p.instruction == pill.instruction,
      );
    await _preferencesService.setCustomPills(_customPills);
    notifyListeners();
  }

  Future<void> addHashtagGroup(HashtagGroup group) async {
    final isFirst = _hashtagGroups.isEmpty;
    final newGroup = isFirst ? group.copyWith(isDefault: true) : group;

    _hashtagGroups = List.of(_hashtagGroups)..add(newGroup);
    await _preferencesService.setHashtagGroups(_hashtagGroups);
    if (newGroup.isDefault) {
      _defaultHashtags = newGroup.hashtags;
    }
    notifyListeners();
  }

  Future<void> removeHashtagGroup(HashtagGroup group) async {
    _hashtagGroups = List.of(_hashtagGroups)
      ..removeWhere((g) => g.id == group.id);

    if (group.isDefault && _hashtagGroups.isNotEmpty) {
      final newDefault = _hashtagGroups.first.copyWith(isDefault: true);
      _hashtagGroups[0] = newDefault;
      _defaultHashtags = newDefault.hashtags;
    } else if (group.isDefault) {
      _defaultHashtags = '';
    }

    await _preferencesService.setHashtagGroups(_hashtagGroups);
    notifyListeners();
  }

  Future<void> setDefaultHashtagGroup(String id) async {
    _hashtagGroups = _hashtagGroups.map((g) {
      if (g.id == id) {
        _defaultHashtags = g.hashtags;
        return g.copyWith(isDefault: true);
      }
      return g.copyWith(isDefault: false);
    }).toList();
    await _preferencesService.setHashtagGroups(_hashtagGroups);
    notifyListeners();
  }

  Future<void> setReadingTextSize(double size) async {
    final clamped = size.clamp(12.0, 24.0);
    if (_readingTextSize == clamped) return;
    await _preferencesService.setReadingTextSize(clamped);
    _readingTextSize = clamped;
    notifyListeners();
  }
}
