import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/domain/models/curated_post.dart';

import 'generate_view_model.dart';

part 'generate_state.freezed.dart';

@freezed
abstract class GenerateUiState with _$GenerateUiState {
  const GenerateUiState._();

  const factory GenerateUiState({
    @Default(PromptLength.medium) PromptLength promptLength,
    @Default(GenerateState.idle) GenerateState status,
    @Default(GeneratingStep.idle) GeneratingStep generatingStep,
    CuratedPost? curatedPost,
    @Default([]) List<String> historyStack,
    @Default([]) List<String> recentInputs,
    String? errorMessage,
    AiProvider? suggestedFallbackProvider,
    String? rateLimitWaitMessage,
    String? validationMessage,
    String? pendingInput,
    @Default(false) bool isResearchModeEnabled,
    @Default([]) List<String> searchSources,
    @Default(true) bool showTitle,
    @Default(true) bool showHashtags,
    @Default(true) bool showSource,
    String? twitterExtractionUrl,
    @Default(false) bool isExtractingImage,
    @Default(false) bool keepStructure,
    @Default(false) bool isEditMode,
  }) = _GenerateUiState;

  bool get canUndo => historyStack.isNotEmpty;
  bool get hasPost => curatedPost != null;
  bool get isGenerating =>
      status == GenerateState.generating || status == GenerateState.researching;
}
