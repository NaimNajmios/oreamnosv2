import 'package:flutter/foundation.dart';
import '../../../../data/models/ai_provider.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../domain/models/app_theme_mode.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._preferencesService) {
    _loadState();
  }

  final PreferencesService _preferencesService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late AppThemeMode _themeMode;
  AppThemeMode get themeMode => _themeMode;

  late AiProvider _selectedProvider;
  AiProvider get selectedProvider => _selectedProvider;

  late String _toneMode;
  String get toneMode => _toneMode;

  late String _defaultHashtags;
  String get defaultHashtags => _defaultHashtags;

  late bool _autoAppendHashtags;
  bool get autoAppendHashtags => _autoAppendHashtags;

  // Track API keys existence securely without exposing them directly in state if not needed,
  // but for the UI, we might just need to know if they exist.
  // We'll load the current provider's API key.
  String? _currentApiKey;
  String? get currentApiKey => _currentApiKey;

  Future<void> _loadState() async {
    _themeMode = _preferencesService.themeMode;
    _selectedProvider = _preferencesService.selectedProvider;
    _toneMode = _preferencesService.toneMode;
    _defaultHashtags = _preferencesService.defaultHashtags;
    _autoAppendHashtags = _preferencesService.autoAppendHashtags;
    
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
    await _loadApiKey(provider);
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
}
