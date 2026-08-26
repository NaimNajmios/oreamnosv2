import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:oreamnos/domain/models/card_brief.dart';
import 'package:oreamnos/domain/models/card_data.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/models/card_config_snapshot.dart';
import 'card_generator_view_model.dart'; // For CardRatio and AppFont enums

part 'card_generator_state.freezed.dart';

@freezed
abstract class CardGeneratorState with _$CardGeneratorState {
  const CardGeneratorState._();

  const factory CardGeneratorState({
    CardBrief? brief,
    CardData? cardData,
    @Default(false) bool isExtracting,
    String? extractionError,
    
    @Default(CardTemplate.socialPost) CardTemplate selectedTemplate,
    @Default(CardRatio.portrait45) CardRatio selectedRatio,
    @Default(AppFont.defaultFont) AppFont selectedFont,
    @Default(1.0) double headlineScale,
    @Default(true) bool templateCompact,

    String? activePanel,
    String? focusedField,

    File? backgroundImage,
    @Default(0.55) double scrimOpacity,
    @Default(false) bool useVignette,
    @Default(false) bool useAutoPalette,
    List<Color>? extractedPalette,

    @Default({}) Set<String> rewritingFields,
    String? rewriteError,

    String? watermarkText,
    @Default(false) bool showWatermark,
    
    @Default(Offset(0.5, 0.2)) Offset headlineOffset,
    @Default(Offset(0.5, 0.5)) Offset subtextOffset,
    @Default(Offset(0.5, 0.8)) Offset microStatOffset,

    @Default([]) List<CardConfigSnapshot> undoStack,
    @Default([]) List<CardConfigSnapshot> redoStack,
  }) = _CardGeneratorState;

  bool get hasBrief => brief != null && !brief!.isEmpty;
  bool get hasImage => backgroundImage != null;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool isRewriting(String field) => rewritingFields.contains(field);

  CardConfigSnapshot toSnapshot() {
    return CardConfigSnapshot(
      cardData: cardData,
      selectedTemplate: selectedTemplate,
      selectedRatio: selectedRatio,
      selectedFont: selectedFont,
      scrimOpacity: scrimOpacity,
      useVignette: useVignette,
      headlineScale: headlineScale,
      templateCompact: templateCompact,
      backgroundImage: backgroundImage,
      useAutoPalette: useAutoPalette,
      extractedPalette: extractedPalette,
      watermarkText: watermarkText,
      showWatermark: showWatermark,
    );
  }
}
