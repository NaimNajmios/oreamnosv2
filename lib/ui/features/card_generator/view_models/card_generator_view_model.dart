import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/data/services/card_data_extractor.dart';
import 'package:oreamnos/data/services/color_extractor.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_data.dart';

// Lightweight — 4 sparse templates only (no heavy stat grids)
enum CardTemplate {
  standard,    // headline uppercase + subtext + microStat pill
  headlineQuote, // large quote-style subtext + headline byline
  breakingNews, // red band + headline
  statBadge,   // headline + prominent microStat
}

// Kept for back-compat fallback mapping — all 4 above map from old 16
extension CardTemplateCompat on CardTemplate {
  static CardTemplate fromLegacy(String name) {
    switch (name) {
      case 'headlineQuote':
        return CardTemplate.headlineQuote;
      case 'breakingNews':
        return CardTemplate.breakingNews;
      case 'topStats':
      case 'transferNews':
        return CardTemplate.statBadge;
      default:
        return CardTemplate.standard;
    }
  }
}

enum CardRatio {
  square(1 / 1, '1:1', 'IG Post • FB'),
  portrait45(4 / 5, '4:5', 'IG Portrait — best reach'),
  story(9 / 16, '9:16', 'Story • Reels • TikTok'),
  wide(16 / 9, '16:9', 'X / YouTube thumb'),
  photo34(3 / 4, '3:4', 'Classic photo');

  const CardRatio(this.ratio, this.label, this.hint);
  final double ratio;
  final String label;
  final String hint;
}

enum AppFont {
  defaultFont,
  classicSerif,
  typewriter,
}

class CardGeneratorViewModel extends ChangeNotifier {
  final CardDataExtractor extractor;
  final ExportService exportService;

  CardGeneratorViewModel({
    required this.extractor,
    required this.exportService,
  });

  // === Brief (sparse companion input) ===
  CardBrief? _brief;
  CardBrief? get brief => _brief;

  // === Extracted polished card data ===
  CardData? cardData;
  bool isExtracting = false;
  String? extractionError;

  // === Design state ===
  CardTemplate selectedTemplate = CardTemplate.standard;
  CardRatio selectedRatio = CardRatio.portrait45;
  AppFont selectedFont = AppFont.defaultFont;
  double headlineScale = 1.0; // 0.85 - 1.15 user-adjustable
  bool templateCompact = true; // emoji-only default

  // Image + scrim (overlay darkness 0.3 - 0.75)
  File? backgroundImage;
  double scrimOpacity = 0.55;
  bool useVignette = false;

  bool get hasBrief => _brief != null && !_brief!.isEmpty;
  bool get hasImage => backgroundImage != null;

  // --- Init from route brief ---
  Future<void> initialize(CardBrief brief, String apiKey) async {
    _brief = brief;
    // Seed CardData immediately from brief so canvas shows something even before LLM
    cardData = CardData.fromBrief(
      headline: brief.headline,
      subtext: brief.subtext,
      microStat: brief.microStat,
    );
    notifyListeners();
    if (brief.modelId.isEmpty || apiKey.isEmpty) return;
    await extractData(apiKey);
  }

  Future<void> extractData(String apiKey) async {
    final b = _brief;
    if (b == null || b.isEmpty) return;
    if (b.modelId.isEmpty || apiKey.isEmpty) return;

    isExtracting = true;
    extractionError = null;
    notifyListeners();

    try {
      final polished = await extractor.extractCardData(
        brief: b,
        provider: b.provider,
        modelId: b.modelId,
        apiKey: apiKey,
      );
      // Merge: LLM headline/subtext/microStat overwrite seeded values, but keep non-empty
      final nextHeadline = polished.headline != 'Generated Card' ? polished.headline : b.headline;
      final nextSubtext = polished.subtext.isNotEmpty ? polished.subtext : b.subtext;
      final nextMicro = polished.microStat ?? b.microStat;
      cardData = CardData.fromBrief(
        headline: nextHeadline,
        subtext: nextSubtext,
        microStat: nextMicro,
      );
    } catch (e) {
      extractionError = e.toString();
      // Keep seeded cardData so user can still edit/export
    } finally {
      isExtracting = false;
      notifyListeners();
    }
  }

  // --- Template / Ratio / Font / Scrim ---
  void setTemplate(CardTemplate template) {
    selectedTemplate = template;
    notifyListeners();
    // No re-extract: same sparse JSON serves all templates
  }

  void setRatio(CardRatio ratio) {
    selectedRatio = ratio;
    notifyListeners();
  }

  void setFont(AppFont font) {
    selectedFont = font;
    notifyListeners();
  }

  void setScrim(double value) {
    scrimOpacity = value.clamp(0.3, 0.75);
    notifyListeners();
  }

  void setVignette(bool v) {
    useVignette = v;
    notifyListeners();
  }

  void setHeadlineScale(double v) {
    headlineScale = v.clamp(0.85, 1.15);
    notifyListeners();
  }

  void toggleTemplateCompact() {
    templateCompact = !templateCompact;
    notifyListeners();
  }

  // --- Inline editing (local, no LLM) — now handles sealed 16 variants (maps to sparse fallback)
  void updateHeadline(String value) {
    final v = value.trim();
    if (cardData == null) {
      cardData = CardData.sparse(headline: v.isEmpty ? 'Generated Card' : v, subtext: '');
    } else {
      final d = cardData!;
      cardData = d.map(
        playerSpotlight: (x) => x.copyWith(playerName: v.isEmpty ? 'N/A' : v),
        headlineQuote: (x) => x.copyWith(headline: v.isEmpty ? 'N/A' : v),
        topStats: (x) => x,
        transferNews: (x) => x.copyWith(playerName: v.isEmpty ? 'N/A' : v),
        breakingNews: (x) => x.copyWith(headline: v.isEmpty ? 'N/A' : v),
        matchPreview: (x) => x.copyWith(homeTeam: v.isEmpty ? 'N/A' : v),
        detailedScoreboard: (x) => x.copyWith(homeTeam: v.isEmpty ? 'N/A' : v),
        onThisDay: (x) => x.copyWith(headline: v.isEmpty ? 'N/A' : v),
        startingXI: (x) => x.copyWith(teamName: v.isEmpty ? 'N/A' : v),
        matchStatsComparison: (x) => x.copyWith(homeTeam: v.isEmpty ? 'N/A' : v),
        socialPost: (x) => x.copyWith(content: v.isEmpty ? 'N/A' : v),
        rivalry: (x) => x.copyWith(player1Name: v.isEmpty ? 'N/A' : v),
        tableStandings: (x) => x.copyWith(leagueName: v.isEmpty ? 'N/A' : v),
        injuryReport: (x) => x.copyWith(teamName: v.isEmpty ? 'N/A' : v),
        contractExpiry: (x) => x.copyWith(teamName: v.isEmpty ? 'N/A' : v),
        awardNominee: (x) => x.copyWith(awardName: v.isEmpty ? 'N/A' : v),
        sparse: (x) => x.copyWith(headline: v.isEmpty ? 'Generated Card' : v),
      );
    }
    notifyListeners();
  }

  void updateSubtext(String value) {
    final v = value.trim();
    if (cardData == null) {
      cardData = CardData.sparse(headline: 'Generated Card', subtext: v);
    } else {
      final d = cardData!;
      cardData = d.map(
        playerSpotlight: (x) => x.copyWith(keyQuote: v.isEmpty ? 'N/A' : v),
        headlineQuote: (x) => x.copyWith(subtext: v.isEmpty ? 'N/A' : v),
        topStats: (x) => x,
        transferNews: (x) => x.copyWith(quote: v.isEmpty ? 'N/A' : v),
        breakingNews: (x) => x.copyWith(subtext: v.isEmpty ? 'N/A' : v),
        matchPreview: (x) => x.copyWith(competition: v.isEmpty ? 'N/A' : v),
        detailedScoreboard: (x) => x.copyWith(competition: v.isEmpty ? 'N/A' : v),
        onThisDay: (x) => x.copyWith(significance: v.isEmpty ? 'N/A' : v),
        startingXI: (x) => x.copyWith(manager: v.isEmpty ? 'N/A' : v),
        matchStatsComparison: (x) => x,
        socialPost: (x) => x.copyWith(metrics: v.isEmpty ? 'N/A' : v),
        rivalry: (x) => x.copyWith(verdict: v.isEmpty ? 'N/A' : v),
        tableStandings: (x) => x.copyWith(matchday: v.isEmpty ? 'N/A' : v),
        injuryReport: (x) => x.copyWith(nextMatch: v.isEmpty ? 'N/A' : v),
        contractExpiry: (x) => x.copyWith(seasonYear: v.isEmpty ? 'N/A' : v),
        awardNominee: (x) => x.copyWith(category: v.isEmpty ? 'N/A' : v),
        sparse: (x) => x.copyWith(subtext: v),
      );
    }
    notifyListeners();
  }

  void updateMicroStat(String value) {
    final v = value.trim();
    final isClear = v.isEmpty;
    if (cardData == null) {
      cardData = CardData.sparse(headline: 'Generated Card', subtext: '', microStat: isClear ? null : v);
    } else {
      final d = cardData!;
      cardData = d.map(
        playerSpotlight: (x) => x.copyWith(keyAction: isClear ? 'N/A' : v),
        headlineQuote: (x) => x.copyWith(category: isClear ? 'N/A' : v),
        topStats: (x) => x,
        transferNews: (x) => x.copyWith(fee: isClear ? 'N/A' : v),
        breakingNews: (x) => x.copyWith(label: isClear ? '🚨 BREAKING' : v),
        matchPreview: (x) => x.copyWith(homeForm: isClear ? 'N/A' : v),
        detailedScoreboard: (x) => x.copyWith(possession: isClear ? 'N/A' : v),
        onThisDay: (x) => x,
        startingXI: (x) => x.copyWith(formation: isClear ? 'N/A' : v),
        matchStatsComparison: (x) => x,
        socialPost: (x) => x.copyWith(handle: isClear ? 'N/A' : v),
        rivalry: (x) => x.copyWith(headToHead: isClear ? 'N/A' : v),
        tableStandings: (x) => x.copyWith(highlightedTeam: isClear ? 'N/A' : v),
        injuryReport: (x) => x.copyWith(recoveryPercentage: isClear ? 'N/A' : v),
        contractExpiry: (x) => x.copyWith(wage: isClear ? 'N/A' : v),
        awardNominee: (x) => x.copyWith(currentFavorite: isClear ? 'N/A' : v),
        sparse: (x) => x.copyWith(microStat: isClear ? null : v),
      );
    }
    notifyListeners();
  }

  bool useAutoPalette = false;
  List<Color>? extractedPalette;

  void setAutoPalette(bool v) {
    useAutoPalette = v;
    notifyListeners();
  }

  // --- Image picking ---
  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 85);
      if (xfile != null) {
        backgroundImage = File(xfile.path);
        extractedPalette = await ColorExtractor.extractPalette(xfile.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  void removeImage() {
    backgroundImage = null;
    extractedPalette = null;
    useAutoPalette = false;
    notifyListeners();
  }

  // --- Export ---
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
      await exportService.shareImage(bytes, text: cardData?.headline ?? '');
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  // Legacy compat — some old screens check cardData.title
  @Deprecated('Use cardData.headline')
  String get legacyTitle => cardData?.headline ?? '';
}
