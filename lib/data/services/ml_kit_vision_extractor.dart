import 'package:oreamnos/domain/services/vision_extractor.dart';

/// Stub extractor — vision / ML Kit on-device extraction is intentionally
/// excluded (v2 verdict). This keeps DI compatibility and prevents
/// `google_mlkit_text_recognition` dependency.
class MLKitVisionExtractor implements IVisionExtractor {
  @override
  Future<String> extractText(String imagePath) async {
    // Vision excluded — return empty to signal no extraction.
    return '';
  }
}
