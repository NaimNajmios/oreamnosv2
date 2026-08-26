import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:oreamnos/domain/services/football_ocr_parser.dart';
import 'package:oreamnos/domain/services/vision_extractor.dart';

class MLKitVisionExtractor implements IVisionExtractor {
  @override
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      return FootballOcrParser.formatForPrompt(
        recognizedText.text,
        addHeader: true,
      );
    } finally {
      textRecognizer.close();
    }
  }
}
