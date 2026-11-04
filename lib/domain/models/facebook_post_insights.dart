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
    required this.fetchedAt,
  });

  final int? impressions;
  final int? reactions;
  final int? clicks;
  final DateTime fetchedAt;

  bool get hasAny => impressions != null || reactions != null || clicks != null;

  Map<String, dynamic> toJson() => {
    'impressions': impressions,
    'reactions': reactions,
    'clicks': clicks,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
  };

  factory FacebookPostInsights.fromJson(Map<String, dynamic> json) {
    return FacebookPostInsights(
      impressions: (json['impressions'] as num?)?.toInt(),
      reactions: (json['reactions'] as num?)?.toInt(),
      clicks: (json['clicks'] as num?)?.toInt(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
