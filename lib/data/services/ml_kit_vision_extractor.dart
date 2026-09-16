import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';
import 'package:oreamnos/domain/services/football_ocr_parser.dart';
import 'package:oreamnos/domain/services/vision_extractor.dart';

/// On-device OCR floor: unlimited, offline, $0 forever.
///
/// Last hop of the $0 vision chain — never fails on quota and never
/// sends bytes off-device.
@LazySingleton(as: IVisionExtractor)
class MLKitVisionExtractor implements IVisionExtractor {
  @override
  Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      if (result.text.trim().isEmpty) return '';
      return FootballOcrParser.formatForPrompt(result.text, addHeader: true);
    } finally {
      await recognizer.close();
    }
  }
}
