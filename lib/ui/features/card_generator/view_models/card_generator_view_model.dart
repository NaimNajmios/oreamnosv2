import 'package:flutter/material.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/data/services/card_data_extractor.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

enum CardTemplate {
  playerSpotlight,
  headlineQuote,
  topStats,
  transferNews,
  breakingNews,
  matchPreview,
  detailedScoreboard,
  onThisDay,
  startingXI,
  matchStatsComparison,
  socialPost,
  rivalry,
  tableStandings,
  injuryReport,
  contractExpiry,
  awardNominee,
}

enum CardBackground {
  solidDark,
  gradientBlue,
  gradientOrange,
  cutout,
  magazineBold,
  offsetCard,
  glassmorphism,
  neonGlow,
  minimalist,
  grunge
}

enum AppFont {
  defaultFont,
  classicSerif,
  typewriter
}

class CardGeneratorViewModel extends ChangeNotifier {
  final CardDataExtractor extractor;
  final ExportService exportService;
  
  CardData? cardData;
  bool isExtracting = false;
  String? extractionError;
  
  CardTemplate selectedTemplate = CardTemplate.playerSpotlight;
  CardBackground selectedBackground = CardBackground.solidDark;
  AppFont selectedFont = AppFont.defaultFont;
  
  CardGeneratorViewModel({
    required this.extractor,
    required this.exportService,
  });

  Future<void> extractData(String generatedText, AiProvider provider, String apiKey, String modelId) async {
    isExtracting = true;
    extractionError = null;
    notifyListeners();

    try {
      cardData = await extractor.extractCardData(
        generatedText: generatedText,
        provider: provider,
        modelId: modelId,
        apiKey: apiKey,
        template: selectedTemplate,
      );
    } catch (e) {
      extractionError = e.toString();
    } finally {
      isExtracting = false;
      notifyListeners();
    }
  }

  void setTemplate(CardTemplate template) {
    selectedTemplate = template;
    notifyListeners();
  }

  void setBackground(CardBackground background) {
    selectedBackground = background;
    notifyListeners();
  }

  void setFont(AppFont font) {
    selectedFont = font;
    notifyListeners();
  }

  Future<bool> saveToGallery(GlobalKey boundaryKey) async {
    try {
      final bytes = await exportService.capturePng(boundaryKey);
      return await exportService.saveToGallery(bytes);
    } catch (e) {
      return false;
    }
  }

  Future<void> shareCard(GlobalKey boundaryKey) async {
    try {
      final bytes = await exportService.capturePng(boundaryKey);
      await exportService.shareImage(bytes, text: cardData?.title ?? '');
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
}
