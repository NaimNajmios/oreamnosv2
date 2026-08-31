import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';
import 'package:oreamnos/domain/models/custom_pill.dart';
import 'package:oreamnos/domain/models/hashtag_group.dart';

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
  final double readingTextSize;
  final String? currentApiKey;
  final String? tavilyApiKey;
  final bool isFanModeEnabled;
  final String fanClubName;

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
    this.readingTextSize = 16.0,
    this.currentApiKey,
    this.tavilyApiKey,
    this.isFanModeEnabled = false,
    this.fanClubName = '',
  });

  SettingsState copyWith({
    bool? isInitialized,
    AppThemeMode? themeMode,
    AiProvider? selectedProvider,
    String? selectedModel,
    bool clearModel = false,
    String? toneMode,
    String? defaultHashtags,
    List<HashtagGroup>? hashtagGroups,
    bool? autoAppendHashtags,
    List<CustomPill>? customPills,
    double? readingTextSize,
    String? currentApiKey,
    bool clearApiKey = false,
    String? tavilyApiKey,
    bool clearTavilyKey = false,
    bool? isFanModeEnabled,
    String? fanClubName,
  }) {
    return SettingsState(
      isInitialized: isInitialized ?? this.isInitialized,
      themeMode: themeMode ?? this.themeMode,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModel: clearModel ? null : (selectedModel ?? this.selectedModel),
      toneMode: toneMode ?? this.toneMode,
      defaultHashtags: defaultHashtags ?? this.defaultHashtags,
      hashtagGroups: hashtagGroups ?? this.hashtagGroups,
      autoAppendHashtags: autoAppendHashtags ?? this.autoAppendHashtags,
      customPills: customPills ?? this.customPills,
      readingTextSize: readingTextSize ?? this.readingTextSize,
      currentApiKey: clearApiKey ? null : (currentApiKey ?? this.currentApiKey),
      tavilyApiKey: clearTavilyKey ? null : (tavilyApiKey ?? this.tavilyApiKey),
      isFanModeEnabled: isFanModeEnabled ?? this.isFanModeEnabled,
      fanClubName: fanClubName ?? this.fanClubName,
    );
  }
}
