import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/core/repositories/card_repository.dart';
import 'package:oreamnos/domain/models/card_config.dart';
import 'package:oreamnos/core/repositories/content_repository.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/color_extractor.dart';
import 'package:oreamnos/data/services/export_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/models/card_config_snapshot.dart';

import 'card_generator_state.dart';

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

enum AppFont { defaultFont, classicSerif, typewriter }

final cardGeneratorViewModelProvider =
    NotifierProvider<CardGeneratorViewModel, CardGeneratorState>(
      CardGeneratorViewModel.new,
    );

class CardGeneratorViewModel extends Notifier<CardGeneratorState> {
  static const int _maxSnapshots = 50;

  late final ExportService _exportService;
  late final PreferencesService _prefsService;

  @override
  CardGeneratorState build() {
    _exportService = getIt<ExportService>();
    _prefsService = getIt<PreferencesService>();
    return CardGeneratorState(
      brandName: _prefsService.brandName,
      brandHandle: _prefsService.brandHandle,
      watermarkText: _prefsService.watermarkText.isNotEmpty
          ? _prefsService.watermarkText
          : (_prefsService.brandHandle.isNotEmpty
                ? _prefsService.brandHandle
                : null),
      showWatermark: _prefsService.showWatermark,
      showBrandFooter: _prefsService.showBrandFooter,
    );
  }

  void _saveSnapshot() {
    final current = state.toSnapshot();
    final newUndo = List<CardConfigSnapshot>.from(state.undoStack)
      ..add(current);
    if (newUndo.length > _maxSnapshots) {
      newUndo.removeAt(0);
    }
    state = state.copyWith(undoStack: newUndo, redoStack: []);
  }

  void undo() {
    if (!state.canUndo) return;
    final current = state.toSnapshot();
    final newUndo = List<CardConfigSnapshot>.from(state.undoStack);
    final snapshot = newUndo.removeLast();
    final newRedo = List<CardConfigSnapshot>.from(state.redoStack)
      ..add(current);

    _applySnapshot(snapshot, newUndo, newRedo);
  }

  void redo() {
    if (!state.canRedo) return;
    final current = state.toSnapshot();
    final newRedo = List<CardConfigSnapshot>.from(state.redoStack);
    final snapshot = newRedo.removeLast();
    final newUndo = List<CardConfigSnapshot>.from(state.undoStack)
      ..add(current);

    _applySnapshot(snapshot, newUndo, newRedo);
  }

  void _applySnapshot(
    CardConfigSnapshot snapshot,
    List<CardConfigSnapshot> undo,
    List<CardConfigSnapshot> redo,
  ) {
    state = state.copyWith(
      cardData: snapshot.cardData,
      selectedTemplate: snapshot.selectedTemplate,
      selectedRatio: snapshot.selectedRatio,
      selectedFont: snapshot.selectedFont,
      scrimOpacity: snapshot.scrimOpacity,
      useVignette: snapshot.useVignette,
      headlineScale: snapshot.headlineScale,
      templateCompact: snapshot.templateCompact,
      backgroundImage: snapshot.backgroundImage,
      useAutoPalette: snapshot.useAutoPalette,
      extractedPalette: snapshot.extractedPalette,
      watermarkText: snapshot.watermarkText,
      showWatermark: snapshot.showWatermark,
      watermarkImage: snapshot.watermarkImage,
      watermarkSize: snapshot.watermarkSize,
      watermarkOffset: snapshot.watermarkOffset,
      brandName: snapshot.brandName,
      brandHandle: snapshot.brandHandle,
      showBrandFooter: snapshot.showBrandFooter,
      imagePosition: snapshot.imagePosition,
      photoFilter: snapshot.photoFilter,
      imageOpacity: snapshot.imageOpacity,
      backgroundBlurRadius: snapshot.backgroundBlurRadius,
      badgeText: snapshot.badgeText,
      accentColor: snapshot.accentColor,
      previewScale: snapshot.previewScale,
      backgroundType: snapshot.backgroundType,
      presetBackground: snapshot.presetBackground,
      textShadowRadius: snapshot.textShadowRadius,
      textShadowColor: snapshot.textShadowColor,
      isGlowEnabled: snapshot.isGlowEnabled,
      headlineOffset: snapshot.headlineOffset,
      subtextOffset: snapshot.subtextOffset,
      microStatOffset: snapshot.microStatOffset,
      undoStack: undo,
      redoStack: redo,
    );
  }

  Future<void> initialize(CardBrief brief, String apiKey) async {
    final sparse = CardData.fromBrief(
      headline: brief.headline,
      subtext: brief.subtext,
      microStat: brief.microStat,
    );
    state = state.copyWith(brief: brief, cardData: sparse);
    if (brief.modelId.isEmpty || apiKey.isEmpty) return;
    await extractData(apiKey);
  }

  Future<void> extractData(String apiKey, {bool isRefresh = false}) async {
    final b = state.brief;
    if (b == null || b.isEmpty) return;
    if (b.modelId.isEmpty || apiKey.isEmpty) return;

    state = state.copyWith(isExtracting: true, extractionError: null);

    try {
      final repo = ref.read(cardRepositoryProvider);
      final repoResult = await repo.extractCardData(
        brief: b,
        provider: b.provider,
        modelId: b.modelId,
        apiKey: apiKey,
        template: state.selectedTemplate,
        isRefresh: isRefresh,
      );
      final polished = repoResult.fold(
        (data) => data,
        (failure) => throw failure,
      );

      CardData newCardData;
      if (polished.headline == 'N/A' && b.headline.isNotEmpty) {
        newCardData = polished.copyWithHeadline(b.headline);
      } else {
        newCardData = polished;
      }

      state = state.copyWith(cardData: newCardData);
    } catch (e) {
      state = state.copyWith(extractionError: e.toString());
    } finally {
      state = state.copyWith(isExtracting: false);
    }
  }

  Future<void> regenerateAllFields() async {
    final provider = state.brief?.provider;
    if (provider == null) return;
    final apiKey = await _prefsService.getApiKey(provider);
    if (apiKey == null || apiKey.isEmpty) return;

    _saveSnapshot();
    await extractData(apiKey, isRefresh: true);
  }

  void setTemplate(CardTemplate template) {
    if (state.selectedTemplate == template) return;

    _saveSnapshot();

    final currentTemplate = state.cardData?.effectiveTemplate;

    state = state.copyWith(
      selectedTemplate: template,
      cardData: state.cardData?.adaptToTemplate(template),
    );

    if (currentTemplate != null &&
        currentTemplate != template &&
        state.brief != null) {
      _reprocessForTemplate();
    }
  }

  Future<void> _reprocessForTemplate() async {
    final provider = state.brief?.provider;
    if (provider == null) return;

    final apiKey = await _prefsService.getApiKey(provider);
    if (apiKey != null && apiKey.isNotEmpty) {
      await extractData(apiKey);
    }
  }

  void setRatio(CardRatio ratio) {
    _saveSnapshot();
    state = state.copyWith(selectedRatio: ratio);
  }

  void setFont(AppFont font) {
    _saveSnapshot();
    state = state.copyWith(selectedFont: font);
  }

  void setScrim(double value) {
    _saveSnapshot();
    state = state.copyWith(scrimOpacity: value.clamp(0.3, 0.75));
  }

  void setVignette(bool v) {
    _saveSnapshot();
    state = state.copyWith(useVignette: v);
  }

  void setHeadlineScale(double v) {
    _saveSnapshot();
    state = state.copyWith(headlineScale: v.clamp(0.85, 1.15));
  }

  void toggleTemplateCompact() {
    _saveSnapshot();
    state = state.copyWith(templateCompact: !state.templateCompact);
  }

  void setBrandName(String? name) {
    _saveSnapshot();
    state = state.copyWith(brandName: name);
    _prefsService.setBrandName(name ?? '');
  }

  void setBrandHandle(String? handle) {
    _saveSnapshot();
    state = state.copyWith(brandHandle: handle);
    _prefsService.setBrandHandle(handle ?? '');
  }

  void setWatermarkText(String? text) {
    _saveSnapshot();
    state = state.copyWith(watermarkText: text);
    _prefsService.setWatermarkText(text ?? '');
  }

  void setShowWatermark(bool show) {
    _saveSnapshot();
    state = state.copyWith(showWatermark: show);
    _prefsService.setShowWatermark(show);
  }

  void setWatermarkSize(double size) {
    _saveSnapshot();
    state = state.copyWith(watermarkSize: size.clamp(24.0, 160.0));
  }

  void setWatermarkOffset(Offset offset) {
    // Clamp 0.05-0.95 to keep inside card, no snapshot for drag (high frequency)
    final clamped = Offset(
      offset.dx.clamp(0.05, 0.95),
      offset.dy.clamp(0.05, 0.95),
    );
    state = state.copyWith(watermarkOffset: clamped);
  }

  void commitWatermarkOffset(Offset offset) {
    _saveSnapshot();
    setWatermarkOffset(offset);
  }

  Future<void> pickWatermarkImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 90);
      if (xfile != null) {
        _saveSnapshot();
        state = state.copyWith(
          watermarkImage: File(xfile.path),
          showWatermark: true,
        );
        _prefsService.setShowWatermark(true);
      }
    } catch (e) {
      debugPrint('pickWatermarkImage error: $e');
    }
  }

  void removeWatermarkImage() {
    _saveSnapshot();
    state = state.copyWith(watermarkImage: null);
  }

  void setImageOpacity(double v) {
    _saveSnapshot();
    state = state.copyWith(imageOpacity: v.clamp(0.2, 1.0));
  }

  void setBackgroundBlurRadius(double v) {
    _saveSnapshot();
    state = state.copyWith(backgroundBlurRadius: v.clamp(0.0, 25.0));
  }

  void setBadgeText(String? text) {
    _saveSnapshot();
    state = state.copyWith(badgeText: text?.isEmpty == true ? null : text);
  }

  void setAccentColor(Color? c) {
    _saveSnapshot();
    state = state.copyWith(accentColor: c);
  }

  void setPreviewScale(double v) {
    _saveSnapshot();
    state = state.copyWith(previewScale: v.clamp(0.8, 1.4));
  }

  void setBackgroundType(BackgroundType t) {
    _saveSnapshot();
    state = state.copyWith(backgroundType: t);
  }

  void setPresetBackground(PresetBackground? p) {
    _saveSnapshot();
    state = state.copyWith(
      presetBackground: p,
      backgroundType: BackgroundType.preset,
    );
  }

  void setTextShadow({double? radius, Color? color, bool? glow}) {
    _saveSnapshot();
    state = state.copyWith(
      textShadowRadius: radius ?? state.textShadowRadius,
      textShadowColor: color ?? state.textShadowColor,
      isGlowEnabled: glow ?? state.isGlowEnabled,
    );
  }

  void setShowBrandFooter(bool show) {
    _saveSnapshot();
    state = state.copyWith(showBrandFooter: show);
    _prefsService.setShowBrandFooter(show);
  }

  void saveDragSnapshot() => _saveSnapshot();

  void updateElementOffset(String field, Offset offset) {
    final clamped = Offset(
      offset.dx.clamp(0.05, 0.95),
      offset.dy.clamp(0.05, 0.95),
    );
    if (field == 'headline') {
      state = state.copyWith(headlineOffset: clamped);
    } else if (field == 'subtext') {
      state = state.copyWith(subtextOffset: clamped);
    } else if (field == 'microStat') {
      state = state.copyWith(microStatOffset: clamped);
    }
  }

  void setActivePanel(String? panel) {
    state = state.copyWith(activePanel: panel);
  }

  void setFocusedField(String? field) {
    state = state.copyWith(focusedField: field);
  }

  void updateHeadline(String value) {
    _saveSnapshot();
    final v = value.trim();
    if (state.cardData == null) {
      state = state.copyWith(
        cardData: CardData.sparse(
          headline: v.isEmpty ? 'Generated Card' : v,
          subtext: '',
        ),
      );
    } else {
      final d = state.cardData!;
      state = state.copyWith(
        cardData: d.map(
          playerSpotlight: (x) => x.copyWith(playerName: v.isEmpty ? 'N/A' : v),
          headlineQuote: (x) => x.copyWith(headline: v.isEmpty ? 'N/A' : v),
          topStats: (x) => x,
          transferNews: (x) => x.copyWith(playerName: v.isEmpty ? 'N/A' : v),
          breakingNews: (x) => x.copyWith(headline: v.isEmpty ? 'N/A' : v),
          matchPreview: (x) => x.copyWith(homeTeam: v.isEmpty ? 'N/A' : v),
          detailedScoreboard: (x) =>
              x.copyWith(homeTeam: v.isEmpty ? 'N/A' : v),
          onThisDay: (x) => x.copyWith(headline: v.isEmpty ? 'N/A' : v),
          startingXI: (x) => x.copyWith(teamName: v.isEmpty ? 'N/A' : v),
          matchStatsComparison: (x) =>
              x.copyWith(homeTeam: v.isEmpty ? 'N/A' : v),
          socialPost: (x) => x.copyWith(content: v.isEmpty ? 'N/A' : v),
          rivalry: (x) => x.copyWith(player1Name: v.isEmpty ? 'N/A' : v),
          tableStandings: (x) => x.copyWith(leagueName: v.isEmpty ? 'N/A' : v),
          injuryReport: (x) => x.copyWith(teamName: v.isEmpty ? 'N/A' : v),
          contractExpiry: (x) => x.copyWith(teamName: v.isEmpty ? 'N/A' : v),
          awardNominee: (x) => x.copyWith(awardName: v.isEmpty ? 'N/A' : v),
          sparse: (x) => x.copyWith(headline: v.isEmpty ? 'Generated Card' : v),
        ),
      );
    }
  }

  void updateCardField(String key, String value) {
    if (state.cardData == null) return;
    _saveSnapshot();

    final json = state.cardData!.toJson();
    json[key] = value.isEmpty ? 'N/A' : value;

    try {
      final updatedData = CardData.fromJson(json);
      state = state.copyWith(cardData: updatedData);
    } catch (e) {
      // Ignore parse errors if somehow mapping fails
    }
  }

  void setSolidBackgroundColor(Color color) {
    _saveSnapshot();
    state = state.copyWith(
      useAutoPalette: false,
      extractedPalette: [color, color],
    );
  }

  void updateSubtext(String value) {
    _saveSnapshot();
    final v = value.trim();
    if (state.cardData == null) {
      state = state.copyWith(
        cardData: CardData.sparse(headline: 'Generated Card', subtext: v),
      );
    } else {
      final d = state.cardData!;
      state = state.copyWith(
        cardData: d.map(
          playerSpotlight: (x) => x.copyWith(keyQuote: v.isEmpty ? 'N/A' : v),
          headlineQuote: (x) => x.copyWith(subtext: v.isEmpty ? 'N/A' : v),
          topStats: (x) => x,
          transferNews: (x) => x.copyWith(quote: v.isEmpty ? 'N/A' : v),
          breakingNews: (x) => x.copyWith(subtext: v.isEmpty ? 'N/A' : v),
          matchPreview: (x) => x.copyWith(competition: v.isEmpty ? 'N/A' : v),
          detailedScoreboard: (x) =>
              x.copyWith(competition: v.isEmpty ? 'N/A' : v),
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
        ),
      );
    }
  }

  void updateMicroStat(String value) {
    _saveSnapshot();
    final v = value.trim();
    final isClear = v.isEmpty;
    if (state.cardData == null) {
      state = state.copyWith(
        cardData: CardData.sparse(
          headline: 'Generated Card',
          subtext: '',
          microStat: isClear ? null : v,
        ),
      );
    } else {
      final d = state.cardData!;
      state = state.copyWith(
        cardData: d.map(
          playerSpotlight: (x) => x.copyWith(keyAction: isClear ? 'N/A' : v),
          headlineQuote: (x) => x.copyWith(category: isClear ? 'N/A' : v),
          topStats: (x) => x,
          transferNews: (x) => x.copyWith(fee: isClear ? 'N/A' : v),
          breakingNews: (x) => x.copyWith(label: isClear ? '🚨 BREAKING' : v),
          matchPreview: (x) => x.copyWith(homeForm: isClear ? 'N/A' : v),
          detailedScoreboard: (x) =>
              x.copyWith(possession: isClear ? 'N/A' : v),
          onThisDay: (x) => x,
          startingXI: (x) => x.copyWith(formation: isClear ? 'N/A' : v),
          matchStatsComparison: (x) => x,
          socialPost: (x) => x.copyWith(handle: isClear ? 'N/A' : v),
          rivalry: (x) => x.copyWith(headToHead: isClear ? 'N/A' : v),
          tableStandings: (x) =>
              x.copyWith(highlightedTeam: isClear ? 'N/A' : v),
          injuryReport: (x) =>
              x.copyWith(recoveryPercentage: isClear ? 'N/A' : v),
          contractExpiry: (x) => x.copyWith(wage: isClear ? 'N/A' : v),
          awardNominee: (x) => x.copyWith(currentFavorite: isClear ? 'N/A' : v),
          sparse: (x) => x.copyWith(microStat: isClear ? null : v),
        ),
      );
    }
  }

  void setImagePosition(ImagePosition position) {
    _saveSnapshot();
    state = state.copyWith(imagePosition: position);
  }

  void setPhotoFilter(PhotoFilter filter) {
    _saveSnapshot();
    state = state.copyWith(photoFilter: filter);
  }

  void setAutoPalette(bool v) {
    _saveSnapshot();
    state = state.copyWith(useAutoPalette: v);
  }

  Future<void> rewriteDynamicField({
    required String fieldKey,
    required AiProvider provider,
    required String modelId,
    required String apiKey,
  }) => _rewriteField(fieldKey, provider, modelId, apiKey);

  Future<void> _rewriteField(
    String field,
    AiProvider provider,
    String modelId,
    String apiKey,
  ) async {
    final json = state.cardData?.toJson();
    final current = json?[field] as String? ?? '';
    if (current.trim().isEmpty || current == 'N/A') return;

    final newRewriting = Set<String>.from(state.rewritingFields)..add(field);
    state = state.copyWith(rewritingFields: newRewriting, rewriteError: null);

    try {
      final repo = getIt<IContentRepository>();
      final res = await repo.rewriteField(
        text: current,
        fieldName: field,
        modelId: modelId,
        apiKey: apiKey,
        provider: provider,
      );
      res.fold(
        (rewritten) {
          final trimmed = rewritten.trim();
          if (trimmed.isEmpty) return;
          final clean = trimmed
              .replaceAll(RegExp(r'^["“”]+|["“”]+$'), '')
              .trim();
          updateCardField(field, clean);
        },
        (failure) {
          state = state.copyWith(rewriteError: failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(rewriteError: e.toString());
    } finally {
      final endRewriting = Set<String>.from(state.rewritingFields)
        ..remove(field);
      state = state.copyWith(rewritingFields: endRewriting);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 85);
      if (xfile != null) {
        _saveSnapshot();
        final palette = await ColorExtractor.extractPalette(xfile.path);
        state = state.copyWith(
          backgroundImage: File(xfile.path),
          extractedPalette: palette,
        );
      }
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  void removeImage() {
    _saveSnapshot();
    state = state.copyWith(
      backgroundImage: null,
      extractedPalette: null,
      useAutoPalette: false,
    );
  }

  double _pixelRatioForRatio(CardRatio ratio) {
    return switch (ratio) {
      CardRatio.square => 3.0,
      CardRatio.portrait45 => 2.8,
      CardRatio.story => 2.5,
      CardRatio.wide => 2.8,
      CardRatio.photo34 => 2.8,
    };
  }

  Future<bool> saveToGallery(GlobalKey boundaryKey) async {
    try {
      final bytes = await _exportService.capturePng(
        boundaryKey,
        pixelRatio: _pixelRatioForRatio(state.selectedRatio),
      );
      return await _exportService.saveToGallery(bytes);
    } catch (e) {
      return false;
    }
  }

  Future<void> shareCard(GlobalKey boundaryKey) async {
    try {
      final bytes = await _exportService.capturePng(
        boundaryKey,
        pixelRatio: _pixelRatioForRatio(state.selectedRatio),
      );
      await _exportService.shareImage(
        bytes,
        text: state.cardData?.headline ?? '',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
}
