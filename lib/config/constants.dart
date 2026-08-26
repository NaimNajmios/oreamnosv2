/// App-wide constants ported from the Android Socurate codebase.
abstract final class AppConstants {
  // === App Info ===
  static const String appName = 'Oreamnos';
  static const String appDescription = 'AI Assisted Social Media Curator';

  // === AI Provider API URLs ===
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String cerebrasBaseUrl = 'https://api.cerebras.ai/v1';

  // === Network Timeouts ===
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration readTimeout = Duration(seconds: 60);

  // === Retry Configuration ===
  static const int maxRetries = 5;
  static const Duration initialBackoff = Duration(seconds: 1);
  static const Duration maxBackoff = Duration(seconds: 32);
  static const double backoffMultiplier = 2.0;

  // === Content Generation ===
  static const double minLengthRatio = 0.4;
  static const double maxLengthRatio = 0.6;
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 2048;

  // === UI ===
  static const int typewriterCharsPerStep = 3;
  static const Duration typewriterDelay = Duration(milliseconds: 1);
  static const Duration staggerDelay = Duration(milliseconds: 30);
  static const Duration colorTransitionDuration = Duration(milliseconds: 200);
  static const int maxSessionHistory = 20;

  // === Storage Keys ===
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGroqApiKey = 'groq_api_key';
  static const String keyOpenRouterApiKey = 'openrouter_api_key';
  static const String keyCerebrasApiKey = 'cerebras_api_key';
  static const String keyTavilyApiKey = 'tavily_api_key';
  static const String keySelectedProvider = 'selected_provider';
  static const String keySelectedModel = 'selected_model';
  static const String keyToneMode = 'tone_mode';
  static const String keyThemeMode = 'theme_mode';
  static const String keyDefaultHashtags = 'default_hashtags';
  static const String keyAutoAppendHashtags = 'auto_append_hashtags';
  static const String keyReadingTextSize = 'reading_text_size';
}
