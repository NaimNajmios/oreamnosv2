/// Metrics Facebook returns for a published post.
///
/// Every field is nullable: Graph omits a metric when the Page lacks the
/// permission or the post is too new. A missing metric must stay hidden in
/// the UI rather than render as a fake zero.
class FacebookPostInsights {
  const FacebookPostInsights({
    this.impressions,
    this.reactions,
    this.clicks,
    this.totalImpressions,
    this.engagedUsers,
    this.negativeFeedback,
    this.reactionsByType,
    required this.fetchedAt,
  });

  /// Unique reach (`post_impressions_unique`).
  final int? impressions;
  final int? reactions;
  final int? clicks;

  /// Total impressions (`post_impressions`), including repeat views.
  final int? totalImpressions;
  final int? engagedUsers;
  final int? negativeFeedback;

  /// Per-reaction counts (like/love/haha/…). `reactions` is the sum.
  final Map<String, int>? reactionsByType;

  final DateTime fetchedAt;

  bool get hasAny =>
      impressions != null ||
      reactions != null ||
      clicks != null ||
      totalImpressions != null ||
      engagedUsers != null ||
      negativeFeedback != null ||
      (reactionsByType?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
    'impressions': impressions,
    'reactions': reactions,
    'clicks': clicks,
    'totalImpressions': totalImpressions,
    'engagedUsers': engagedUsers,
    'negativeFeedback': negativeFeedback,
    'reactionsByType': reactionsByType,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
  };

  factory FacebookPostInsights.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactionsByType'];
    final reactionsByType = rawReactions is Map
        ? {
            for (final entry in rawReactions.entries)
              if (_asInt(entry.value) != null)
                entry.key.toString(): _asInt(entry.value)!,
          }
        : null;
    return FacebookPostInsights(
      impressions: (json['impressions'] as num?)?.toInt(),
      reactions: (json['reactions'] as num?)?.toInt(),
      clicks: (json['clicks'] as num?)?.toInt(),
      totalImpressions: (json['totalImpressions'] as num?)?.toInt(),
      engagedUsers: (json['engagedUsers'] as num?)?.toInt(),
      negativeFeedback: (json['negativeFeedback'] as num?)?.toInt(),
      reactionsByType: reactionsByType,
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt();
    return null;
  }
}
