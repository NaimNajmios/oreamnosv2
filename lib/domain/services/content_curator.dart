abstract class IContentCurator {
  /// Generates a social media post from the provided URL or text content.
  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required String tone,
    required String defaultHashtags,
  });
}

