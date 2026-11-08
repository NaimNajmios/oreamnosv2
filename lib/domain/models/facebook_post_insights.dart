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
    this.uniqueViewers,
    this.comments,
    this.shares,
    this.activityByActionType,
    required this.fetchedAt,
  });

  /// Legacy unique reach (`post_impressions_unique`). Meta retired this
  /// metric in June 2026; kept for cached records only.
  final int? impressions;

  /// Legacy total impressions (`post_impressions`). Cached records only.
  final int? totalImpressions;
  final int? engagedUsers;
  final int? negativeFeedback;

  /// Current post metric: unique post viewers
  /// (`post_total_media_view_unique`).
  final int? uniqueViewers;

  /// Engagement counts from the post's summary fields.
  final int? reactions;
  final int? comments;
  final int? shares;

  /// Legacy click metric, cached records only.
  final int? clicks;

  /// Per-reaction counts (like/love/haha/…). `reactions` is the sum.
  final Map<String, int>? reactionsByType;

  /// Action → count from `post_activity_by_action_type`.
  final Map<String, int>? activityByActionType;

  final DateTime fetchedAt;

  bool get hasAny =>
      uniqueViewers != null ||
      impressions != null ||
      reactions != null ||
      comments != null ||
      shares != null ||
      clicks != null ||
      totalImpressions != null ||
      engagedUsers != null ||
      negativeFeedback != null ||
      (reactionsByType?.isNotEmpty ?? false) ||
      (activityByActionType?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
    'impressions': impressions,
    'reactions': reactions,
    'clicks': clicks,
    'totalImpressions': totalImpressions,
    'engagedUsers': engagedUsers,
    'negativeFeedback': negativeFeedback,
    'reactionsByType': reactionsByType,
    'uniqueViewers': uniqueViewers,
    'comments': comments,
    'shares': shares,
    'activityByActionType': activityByActionType,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
  };

  factory FacebookPostInsights.fromJson(Map<String, dynamic> json) {
    return FacebookPostInsights(
      impressions: (json['impressions'] as num?)?.toInt(),
      reactions: (json['reactions'] as num?)?.toInt(),
      clicks: (json['clicks'] as num?)?.toInt(),
      totalImpressions: (json['totalImpressions'] as num?)?.toInt(),
      engagedUsers: (json['engagedUsers'] as num?)?.toInt(),
      negativeFeedback: (json['negativeFeedback'] as num?)?.toInt(),
      reactionsByType: _intMap(json['reactionsByType']),
      uniqueViewers: (json['uniqueViewers'] as num?)?.toInt(),
      comments: (json['comments'] as num?)?.toInt(),
      shares: (json['shares'] as num?)?.toInt(),
      activityByActionType: _intMap(json['activityByActionType']),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  static Map<String, int>? _intMap(Object? raw) {
    if (raw is! Map) return null;
    final result = <String, int>{};
    for (final entry in raw.entries) {
      final value = _asInt(entry.value);
      if (value != null) result[entry.key.toString()] = value;
    }
    return result.isEmpty ? null : result;
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return num.tryParse(value)?.toInt();
    return null;
  }
}
