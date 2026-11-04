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

  // === Facebook Publishing ===
  // Page publishing goes through the Graph API; the version constant keeps
  // each call pinned in one place (older versions eventually get retired).
  static const String facebookGraphBaseUrl = 'https://graph.facebook.com';
  static const String facebookGraphVersion = 'v23.0';

  // === Network Timeouts ===
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration readTimeout = Duration(seconds: 15);

  // === Retry Configuration ===
  static const int maxRetries = 4;
  static const Duration initialBackoff = Duration(milliseconds: 500);
  static const Duration maxBackoff = Duration(seconds: 60);
  static const double backoffMultiplier = 2.0;

  // === Generation Receive Timeout ===
  // Gemini `generateContent` is non-streaming: the full JSON body only
  // arrives after the server finishes generating, so the pooled 15s
  // receiveTimeout fires mid-generation on long posts/images. Each timed-out
  // attempt was previously retried up to 4× (one tap → up to 5 counted
  // requests) which silently exhausted even generous per-minute quotas.
  // Generation requests override with a generous receive window; short
  // pooling/lookup calls keep the shared BaseOptions timeout.
  static const Duration generationReceiveTimeout = Duration(seconds: 90);
  static const Duration shortGenerationReceiveTimeout = Duration(seconds: 60);

  // === Photo Upload Receive Timeout ===
  // `/{page-id}/photos` is a multipart upload: a ~1MB JPEG on a slow link can
  // exceed the shared 15s receiveTimeout while Facebook still finishes
  // processing the photo. Aborting client-side here is dangerous — Facebook
  // often publishes the photo anyway, and the user's retry then hits the
  // duplicate rejection (code 506). Photo requests override with a generous
  // receive window, mirroring `generationReceiveTimeout` for Gemini.
  static const Duration photoUploadTimeout = Duration(seconds: 60);

  // === 429 Retry Policy ===
  // 429s get at most one honoring retry, and only when the provider-supplied
  // wait is short. Longer/unknown quota windows propagate immediately so the
  // ViewModel fallback chain can switch provider instead of idling.
  static const int maxRetriesOn429 = 1;
  static const int retry429MaxWaitMs = 10000;

  // === Daily Quota Visibility (estimated free-tier RPD) ===
  // Amber warning on the Usage tab when the day's request count crosses
  // this fraction of the model budget.
  static const double dailyQuotaWarnThreshold = 0.8;
  // Conservative default for models not in the DailyUsageService budget
  // table.
  static const int defaultDailyQuota = 500;

  // === Content Generation ===
  static const double minLengthRatio = 0.4;
  static const double maxLengthRatio = 0.6;
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 2048;

  /// Output cap for full post generation/refinement. Malay tokenizes poorly
  /// on most models, so 2048 used to cut long posts mid-sentence (and left
  /// the JSON unterminated). The 90s receive window still bounds latency;
  /// `JsonCleaner.repairTruncated` is the safety net if this is hit.
  static const int generationMaxTokens = 4096;

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
  static const String keyLastTestOkPrefix = 'last_test_ok_';
  static const String keyLastTestedAtPrefix = 'last_tested_at_';
  static const String keyToneMode = 'tone_mode';
  static const String keyThemeMode = 'theme_mode';
  static const String keyDefaultHashtags = 'default_hashtags';
  static const String keyAutoAppendHashtags = 'auto_append_hashtags';
  static const String keyReadingTextSize = 'reading_text_size';
  static const String keyPersistGenerationOptions =
      'persist_generation_options';
  static const String keyLastPromptLength = 'last_prompt_length';
  static const String keyLastIsResearchMode = 'last_is_research_mode';
  static const String keyLastKeepStructure = 'last_keep_structure';

  // === Facebook Publishing (secure + prefs) ===
  static const String keyFacebookPageToken = 'facebook_page_token';
  static const String keyFacebookPageId = 'facebook_page_id';
  static const String keyFacebookPageName = 'facebook_page_name';
  static const String keyFacebookPagePicture = 'facebook_page_picture';
  static const String keyFacebookPages = 'facebook_pages';
  static const String keyFacebookActivePage = 'facebook_active_page';
  static const String keyFacebookHistory = 'facebook_publish_history';
  static const String keyFacebookDraft = 'facebook_compose_draft';
  static const String keyFacebookDrafts = 'facebook_drafts';
  static const String keyFacebookActiveDraft = 'facebook_active_draft';

  /// Per-Page token key. Only derived Page tokens ever use this shape.
  static String facebookPageTokenKey(String pageId) =>
      'facebook_page_token_$pageId';
}
