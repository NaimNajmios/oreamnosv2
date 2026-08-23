import '../../ui/features/card_generator/view_models/card_generator_view_model.dart';

abstract class IContentCurator {
  /// Generates a social media post from the provided URL or text content.
  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required String tone,
    required String defaultHashtags,
  });

  /// Extracts structured JSON data from a generated post to be used for the Card Generator.
  Future<String> extractCardData({
    required String generatedText,
    required String modelId,
    required String apiKey,
    required CardTemplate template,
  });
}
