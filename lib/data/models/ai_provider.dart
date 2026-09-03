/// Supported AI providers.
/// Mirrors the Android app's multi-provider architecture.
enum AiProvider {
  gemini(
    displayName: 'Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models',
    defaultModelId: 'gemini-2.0-flash',
  ),
  groq(
    displayName: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModelId: 'llama-3.3-70b-versatile',
  ),
  openRouter(
    displayName: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModelId: 'meta-llama/llama-3.3-70b-instruct:free',
  ),
  cerebras(
    displayName: 'Cerebras',
    baseUrl: 'https://api.cerebras.ai/v1',
    defaultModelId: 'llama-3.3-70b',
  );

  const AiProvider({
    required this.displayName,
    required this.baseUrl,
    required this.defaultModelId,
  });

  final String displayName;
  final String baseUrl;

  /// Offline fallback model id (Android `CuratorFactory` parity) used when
  /// live `fetchModels` fails, e.g. airplane mode.
  final String defaultModelId;

  /// Fallback chain: Gemini -> Groq -> OpenRouter -> Cerebras -> Gemini
  AiProvider get nextFallback {
    return switch (this) {
      AiProvider.gemini => AiProvider.groq,
      AiProvider.groq => AiProvider.openRouter,
      AiProvider.openRouter => AiProvider.cerebras,
      AiProvider.cerebras => AiProvider.gemini,
    };
  }
}
