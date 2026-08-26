abstract class IVisionExtractor {
  /// Extracts text from an image file at the given [imagePath].
  Future<String> extractText(String imagePath);
}
