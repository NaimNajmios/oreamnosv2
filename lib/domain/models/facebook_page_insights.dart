/// One day in a Page insights range.
class PageInsightPoint {
  const PageInsightPoint({
    required this.day,
    this.mediaViews,
    this.follows,
    this.engagements,
  });

  final DateTime day;
  final int? mediaViews;
  final int? follows;
  final int? engagements;

  PageInsightPoint copyWith({int? mediaViews, int? follows, int? engagements}) {
    return PageInsightPoint(
      day: day,
      mediaViews: mediaViews ?? this.mediaViews,
      follows: follows ?? this.follows,
      engagements: engagements ?? this.engagements,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day.toIso8601String(),
    'mediaViews': mediaViews,
    'follows': follows,
    'engagements': engagements,
  };

  factory PageInsightPoint.fromJson(Map<String, dynamic> json) {
    return PageInsightPoint(
      day:
          DateTime.tryParse(json['day']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      mediaViews: (json['mediaViews'] as num?)?.toInt(),
      follows: (json['follows'] as num?)?.toInt(),
      engagements: (json['engagements'] as num?)?.toInt(),
    );
  }
}

/// Cached Page-level performance snapshot. Metrics are nullable individually:
/// Meta may omit a metric for a range or the token may lack the Page task.
class FacebookPageInsights {
  const FacebookPageInsights({
    required this.pageId,
    required this.points,
    required this.fetchedAt,
    this.hasMediaViews = false,
    this.hasFollows = false,
    this.hasEngagements = false,
  });

  final String pageId;
  final List<PageInsightPoint> points;
  final DateTime fetchedAt;
  final bool hasMediaViews;
  final bool hasFollows;
  final bool hasEngagements;

  bool get hasAny =>
      hasMediaViews || hasFollows || hasEngagements || points.isNotEmpty;

  int? get totalMediaViews => _total((p) => p.mediaViews);
  int? get totalFollows => _total((p) => p.follows);
  int? get totalEngagements => _total((p) => p.engagements);

  int? _total(int? Function(PageInsightPoint) read) {
    var found = false;
    var sum = 0;
    for (final point in points) {
      final value = read(point);
      if (value == null) continue;
      found = true;
      sum += value;
    }
    return found ? sum : null;
  }

  Map<String, dynamic> toJson() => {
    'pageId': pageId,
    'points': points.map((p) => p.toJson()).toList(),
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'hasMediaViews': hasMediaViews,
    'hasFollows': hasFollows,
    'hasEngagements': hasEngagements,
  };

  factory FacebookPageInsights.fromJson(Map<String, dynamic> json) {
    final raw = json['points'];
    return FacebookPageInsights(
      pageId: json['pageId']?.toString() ?? '',
      points: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => PageInsightPoint.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      fetchedAt:
          DateTime.tryParse(json['fetchedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      hasMediaViews: json['hasMediaViews'] as bool? ?? false,
      hasFollows: json['hasFollows'] as bool? ?? false,
      hasEngagements: json['hasEngagements'] as bool? ?? false,
    );
  }
}
