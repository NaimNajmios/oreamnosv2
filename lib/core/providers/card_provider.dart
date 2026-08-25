import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/card_data_extractor.dart';
import '../../data/services/export_service.dart';
import '../../domain/models/card_brief.dart';
import '../../domain/models/card_data.dart';

// Re-export legacy enums for incremental migration
// These remain defined in ViewModel file for now to avoid breaking imports
// Phase B will centralize them here

class CardGeneratorState {
  final CardBrief? brief;
  final CardData? cardData;
  final bool isExtracting;
  final String? extractionError;
  final String selectedTemplate; // keep as String for incremental
  final String selectedRatio;
  final bool hasImage;

  const CardGeneratorState({
    this.brief,
    this.cardData,
    this.isExtracting = false,
    this.extractionError,
    this.selectedTemplate = 'standard',
    this.selectedRatio = 'portrait45',
    this.hasImage = false,
  });

  CardGeneratorState copyWith({
    CardBrief? brief,
    CardData? cardData,
    bool? isExtracting,
    String? extractionError,
    bool clearError = false,
    String? selectedTemplate,
    String? selectedRatio,
    bool? hasImage,
  }) {
    return CardGeneratorState(
      brief: brief ?? this.brief,
      cardData: cardData ?? this.cardData,
      isExtracting: isExtracting ?? this.isExtracting,
      extractionError: clearError ? null : (extractionError ?? this.extractionError),
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      selectedRatio: selectedRatio ?? this.selectedRatio,
      hasImage: hasImage ?? this.hasImage,
    );
  }
}

class CardGeneratorNotifier extends Notifier<CardGeneratorState> {
  @override
  CardGeneratorState build() => const CardGeneratorState();

  Future<void> initialize(CardBrief brief, String apiKey) async {
    state = state.copyWith(brief: brief, cardData: CardData.fromBrief(headline: brief.headline, subtext: brief.subtext, microStat: brief.microStat));
    if (brief.modelId.isEmpty || apiKey.isEmpty) return;
    await extractData(apiKey);
  }

  Future<void> extractData(String apiKey) async {
    final b = state.brief;
    if (b == null || b.isEmpty) return;
    if (b.modelId.isEmpty || apiKey.isEmpty) return;
    state = state.copyWith(isExtracting: true, clearError: true);
    try {
      final extractor = ref.read(cardDataExtractorProvider);
      final polished = await extractor.extractCardData(brief: b, provider: b.provider, modelId: b.modelId, apiKey: apiKey);
      final nextHeadline = polished.headline != 'Generated Card' ? polished.headline : b.headline;
      final nextSubtext = polished.subtext.isNotEmpty ? polished.subtext : b.subtext;
      final nextMicro = polished.microStat ?? b.microStat;
      state = state.copyWith(cardData: CardData.fromBrief(headline: nextHeadline, subtext: nextSubtext, microStat: nextMicro), isExtracting: false);
    } catch (e) {
      state = state.copyWith(isExtracting: false, extractionError: e.toString());
    }
  }

  void updateHeadline(String v) {
    final data = state.cardData;
    if (data == null) {
      state = state.copyWith(cardData: CardData.fromBrief(headline: v.trim(), subtext: ''));
    } else {
      state = state.copyWith(cardData: data.copyWith(headline: v.trim()));
    }
  }

  void updateSubtext(String v) {
    final data = state.cardData;
    if (data == null) {
      state = state.copyWith(cardData: CardData.fromBrief(headline: '', subtext: v.trim()));
    } else {
      state = state.copyWith(cardData: data.copyWith(subtext: v.trim()));
    }
  }

  void updateMicroStat(String v) {
    final data = state.cardData;
    final trimmed = v.trim();
    if (data == null) {
      state = state.copyWith(cardData: CardData.fromBrief(headline: '', subtext: '', microStat: trimmed.isEmpty ? null : trimmed));
    } else {
      if (trimmed.isEmpty) {
        state = state.copyWith(cardData: data.copyWith(clearMicroStat: true));
      } else {
        state = state.copyWith(cardData: data.copyWith(microStat: trimmed));
      }
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 85);
      if (xfile != null) {
        // For Riverpod state, store path; UI will handle File via legacy ViewModel until full migration
        state = state.copyWith(hasImage: true);
      }
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  void removeImage() => state = state.copyWith(hasImage: false);

  Future<bool> saveToGallery(GlobalKey boundaryKey) async {
    try {
      final export = ref.read(exportServiceProvider);
      final bytes = await export.capturePng(boundaryKey);
      return await export.saveToGallery(bytes);
    } catch (_) {
      return false;
    }
  }

  Future<void> shareCard(GlobalKey boundaryKey) async {
    try {
      final export = ref.read(exportServiceProvider);
      final bytes = await export.capturePng(boundaryKey);
      await export.shareImage(bytes, text: state.cardData?.headline ?? '');
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
}

final cardDataExtractorProvider = Provider<CardDataExtractor>((ref) => CardDataExtractor());
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());
final cardGeneratorProvider = NotifierProvider<CardGeneratorNotifier, CardGeneratorState>(CardGeneratorNotifier.new);
