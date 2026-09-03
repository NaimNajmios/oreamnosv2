import '../models/card_brief.dart';
import '../models/card_template.dart';
import '../models/curated_post.dart';

abstract class IContentCurator {
  /// Generates a social media post from the provided URL or text content.
  /// Legacy: returns raw markdown string for backward compat.
  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required String tone,
    required String defaultHashtags,
  });

  /// Structured generation — returns CuratedPost with separate title/body/hashtags/source.
  Future<CuratedPost> generateStructuredPost({
    required dynamic content, // String or ExtractedArticle
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    List<String> searchSources = const [],
    bool keepStructure = false,
    bool isFanModeEnabled = false,
    String fanClubName = '',
    String length = 'medium',
  });

  /// Full refinement pipeline (Android `refinePost` parity): applies a list
  /// of refinement keys (`rephrase`, `recheck_flow`, `recheck_wording`) and/or
  /// free-text custom instructions (user pills) to [original] in one pass.
  Future<CuratedPost> refinePost({
    required CuratedPost original,
    required List<String> refinements,
    required String modelId,
    required String apiKey,
    bool includeSource = true,
    bool keepStructure = false,
  });

  /// Extracts structured JSON data from a generated post to be used for the Card Generator.
  /// [brief] is the sparse companion input (headline + hook). Implementations must use
  /// CardPromptManager.buildPrompt(template, brief.promptContext, isRefresh) and return raw JSON string.
  Future<String> extractCardData({
    required CardBrief brief,
    required String modelId,
    required String apiKey,
    CardTemplate? template,
    bool isRefresh = false,
  });

  Future<String> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
  });
}
