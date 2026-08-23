/// Supported AI providers.
/// Mirrors the Android app's multi-provider architecture.
enum AiProvider {
  gemini(
    displayName: 'Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models',
  ),
  groq(
    displayName: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
  ),
  openRouter(
    displayName: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
  ),
  cerebras(
    displayName: 'Cerebras',
    baseUrl: 'https://api.cerebras.ai/v1',
  );

  const AiProvider({required this.displayName, required this.baseUrl});

  final String displayName;
  final String baseUrl;

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
