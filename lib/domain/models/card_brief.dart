import 'package:equatable/equatable.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

/// Lightweight companion args for the card studio.
/// The card is intentionally sparse: headline + one hook sentence + optional micro-proof.
/// It accompanies the full caption (title + body + hashtags + source), not replaces it.
class CardBrief extends Equatable {
  /// Punchy headline — ≤60 chars, derived from CuratedPost.title (front-page hook).
  final String headline;

  /// One-sentence tease — ≤90 chars, first sentence of bodyMarkdown.
  final String subtext;

  /// Optional single proof token e.g. "Hat-trick • 90'" or "" — mined by LLM or null.
  final String? microStat;

  final AiProvider provider;
  final String modelId;

  const CardBrief({
    required this.headline,
    required this.subtext,
    this.microStat,
    required this.provider,
    required this.modelId,
  });

  /// Compact prompt context for extractor — not the full article.
  String get promptContext {
    final parts = <String>[];
    if (headline.trim().isNotEmpty) parts.add(headline.trim());
    if (subtext.trim().isNotEmpty) parts.add(subtext.trim());
    if (microStat != null && microStat!.trim().isNotEmpty) {
      parts.add(microStat!.trim());
    }
    return parts.join('\n\n');
  }

  bool get isEmpty => headline.trim().isEmpty && subtext.trim().isEmpty;

  CardBrief copyWith({
    String? headline,
    String? subtext,
    String? microStat,
    AiProvider? provider,
    String? modelId,
  }) {
    return CardBrief(
      headline: headline ?? this.headline,
      subtext: subtext ?? this.subtext,
      microStat: microStat ?? this.microStat,
      provider: provider ?? this.provider,
      modelId: modelId ?? this.modelId,
    );
  }

  factory CardBrief.fromJson(Map<String, dynamic> json) {
    return CardBrief(
      headline: (json['headline'] as String?) ?? (json['title'] as String?) ?? '',
      subtext: (json['subtext'] as String?) ?? (json['subtitle'] as String?) ?? '',
      microStat: json['microStat'] as String?,
      provider: _providerFromString(json['provider'] as String?),
      modelId: (json['modelId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'subtext': subtext,
        'microStat': microStat,
        'provider': provider.name,
        'modelId': modelId,
      };

  static AiProvider _providerFromString(String? v) {
    if (v == null) return AiProvider.gemini;
    for (final p in AiProvider.values) {
      if (p.name == v) return p;
    }
    return AiProvider.gemini;
  }

  /// Build a brief from a CuratedPost-like title/body pair.
  /// Truncates headline to 60 chars at word boundary, subtext to first sentence ≤90.
  static CardBrief fromPost({
    required String title,
    required String bodyMarkdown,
    required AiProvider provider,
    required String modelId,
  }) {
    final headline = _truncateHeadline(title);
    final subtext = _firstSentence(bodyMarkdown);
    return CardBrief(
      headline: headline,
      subtext: subtext,
      microStat: null,
      provider: provider,
      modelId: modelId,
    );
  }

  static String _truncateHeadline(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.length <= 60) return s;
    // Cut at word boundary
    var cut = s.substring(0, 60);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace > 30) cut = cut.substring(0, lastSpace);
    return cut.trim();
  }

  static String _firstSentence(String body) {
    var s = body.trim();
    if (s.isEmpty) return '';
    // Take first paragraph only
    final firstPara = s.split(RegExp(r'\n\s*\n')).first.trim();
    // Normalize whitespace
    s = firstPara.replaceAll(RegExp(r'\s+'), ' ');
    // Extract first sentence by punctuation
    final match = RegExp(r'^(.+?[.!?])(\s|$)').firstMatch(s);
    String sentence;
    if (match != null) {
      sentence = match.group(1)!.trim();
    } else {
      sentence = s;
    }
    if (sentence.length > 90) {
      var cut = sentence.substring(0, 90);
      final lastSpace = cut.lastIndexOf(' ');
      if (lastSpace > 45) cut = cut.substring(0, lastSpace);
      sentence = cut.trim();
    }
    return sentence;
  }

  @override
  List<Object?> get props => [headline, subtext, microStat, provider, modelId];
}
