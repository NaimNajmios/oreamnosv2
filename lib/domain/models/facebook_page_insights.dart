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

/// Aggregated metrics for one period. Follows is a running total, so it uses
/// the latest point instead of a sum.
class FacebookInsightTotals {
  const FacebookInsightTotals({
    this.mediaViews,
    this.engagements,
    this.follows,
  });

  final int? mediaViews;
  final int? engagements;
  final int? follows;
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
    this.unavailableMetrics = const [],
    this.rangeDays = 28,
    this.previousPoints = const [],
    this.previousUnavailableMetrics = const [],
  });

  final String pageId;
  final List<PageInsightPoint> points;
  final DateTime fetchedAt;
  final bool hasMediaViews;
  final bool hasFollows;
  final bool hasEngagements;

  /// Metrics Meta rejected for this Page/range. The rest of the snapshot is
  /// still valid, so the UI can show partial data instead of nothing.
  final List<String> unavailableMetrics;

  /// Range the snapshot covers (7, 28, or 90 days).
  final int rangeDays;

  /// The immediately preceding window, when it could be fetched.
  final List<PageInsightPoint> previousPoints;
  final List<String> previousUnavailableMetrics;

  bool get hasAny =>
      hasMediaViews || hasFollows || hasEngagements || points.isNotEmpty;

  bool get hasPrevious => previousPoints.isNotEmpty;

  FacebookInsightTotals get currentTotals => _totalsFor(points);

  FacebookInsightTotals get previousTotals => _totalsFor(previousPoints);

  int? get totalMediaViews => currentTotals.mediaViews;
  int? get totalFollows => currentTotals.follows;
  int? get totalEngagements => currentTotals.engagements;

  static FacebookInsightTotals _totalsFor(List<PageInsightPoint> points) {
    int? sum(int? Function(PageInsightPoint) read) {
      var found = false;
      var total = 0;
      for (final point in points) {
        final value = read(point);
        if (value == null) continue;
        found = true;
        total += value;
      }
      return found ? total : null;
    }

    int? latest(int? Function(PageInsightPoint) read) {
      for (final point in points.reversed) {
        final value = read(point);
        if (value != null) return value;
      }
      return null;
    }

    return FacebookInsightTotals(
      mediaViews: sum((p) => p.mediaViews),
      engagements: sum((p) => p.engagements),
      follows: latest((p) => p.follows),
    );
  }

  FacebookPageInsights copyWith({
    List<PageInsightPoint>? previousPoints,
    List<String>? previousUnavailableMetrics,
  }) {
    return FacebookPageInsights(
      pageId: pageId,
      points: points,
      fetchedAt: fetchedAt,
      hasMediaViews: hasMediaViews,
      hasFollows: hasFollows,
      hasEngagements: hasEngagements,
      unavailableMetrics: unavailableMetrics,
      rangeDays: rangeDays,
      previousPoints: previousPoints ?? this.previousPoints,
      previousUnavailableMetrics:
          previousUnavailableMetrics ?? this.previousUnavailableMetrics,
    );
  }

  Map<String, dynamic> toJson() => {
    'pageId': pageId,
    'points': points.map((p) => p.toJson()).toList(),
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'hasMediaViews': hasMediaViews,
    'hasFollows': hasFollows,
    'hasEngagements': hasEngagements,
    'unavailableMetrics': unavailableMetrics,
    'rangeDays': rangeDays,
    'previousPoints': previousPoints.map((p) => p.toJson()).toList(),
    'previousUnavailableMetrics': previousUnavailableMetrics,
  };

  factory FacebookPageInsights.fromJson(Map<String, dynamic> json) {
    final raw = json['points'];
    final rawPrevious = json['previousPoints'];
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
      unavailableMetrics:
          (json['unavailableMetrics'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      rangeDays: (json['rangeDays'] as num?)?.toInt() ?? 28,
      previousPoints: rawPrevious is List
          ? rawPrevious
                .whereType<Map>()
                .map(
                  (e) => PageInsightPoint.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      previousUnavailableMetrics:
          (json['previousUnavailableMetrics'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}
