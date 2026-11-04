/// Lifecycle of a locally tracked Facebook post.
enum FacebookPostStatus {
  /// Live on the Page.
  published,

  /// Accepted by Graph with `published=false` + `scheduled_publish_time`.
  scheduled,

  /// Scheduling/publishing failed after a local record was created.
  failed,
}

/// One successful publish (or scheduled post), persisted locally (capped at
/// 50, mirrors [UsageLog]'s prefs-JSON shape). Permalink is built from
/// `post_id` (photo posts) or the object id (text posts).
class FacebookPostRecord {
  const FacebookPostRecord({
    required this.id,
    required this.postId,
    required this.snippet,
    required this.timestamp,
    required this.hasImage,
    required this.permalink,
    this.message = '',
    this.localImagePaths = const [],
    this.status = FacebookPostStatus.published,
    this.scheduledAt,
    this.pageId = '',
    this.pageName = '',
    this.errorMessage,
    this.impressions,
    this.reactions,
    this.clicks,
    this.insightsFetchedAt,
  });

  final String id;
  final String postId;

  /// First line(s) of the plain-text message shown in the history list.
  final String snippet;

  /// Full plain-text message, kept so a past caption can be reused.
  final String message;
  final DateTime timestamp;
  final bool hasImage;

  /// Copies of the post's images in app documents (temp files are purged),
  /// used as the history thumbnails.
  final List<String> localImagePaths;
  final String permalink;

  final FacebookPostStatus status;

  /// Local time the post is due (scheduled records only).
  final DateTime? scheduledAt;
  final String pageId;
  final String pageName;
  final String? errorMessage;

  /// Optional Graph insights. `null` means "not available", not zero.
  final int? impressions;
  final int? reactions;
  final int? clicks;
  final DateTime? insightsFetchedAt;

  bool get hasInsights =>
      impressions != null || reactions != null || clicks != null;

  /// Legacy single-thumbnail accessor.
  String? get localImagePath =>
      localImagePaths.isEmpty ? null : localImagePaths.first;

  bool get isScheduled => status == FacebookPostStatus.scheduled;
  bool get isPublished => status == FacebookPostStatus.published;
  bool get isFailed => status == FacebookPostStatus.failed;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.month}/${timestamp.day} $h:$m';
  }

  String get formattedScheduledTime {
    final at = scheduledAt;
    if (at == null) return '';
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '${at.month}/${at.day} $h:$m';
  }

  /// Caption to seed a new draft with (falls back to the snippet).
  String get reusableCaption => message.trim().isEmpty ? snippet : message;

  FacebookPostRecord copyWith({
    String? postId,
    String? snippet,
    String? message,
    DateTime? timestamp,
    bool? hasImage,
    List<String>? localImagePaths,
    String? permalink,
    FacebookPostStatus? status,
    Object? scheduledAt = _sentinel,
    String? pageId,
    String? pageName,
    Object? errorMessage = _sentinel,
    Object? impressions = _sentinel,
    Object? reactions = _sentinel,
    Object? clicks = _sentinel,
    Object? insightsFetchedAt = _sentinel,
  }) {
    return FacebookPostRecord(
      id: id,
      postId: postId ?? this.postId,
      snippet: snippet ?? this.snippet,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      hasImage: hasImage ?? this.hasImage,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      permalink: permalink ?? this.permalink,
      status: status ?? this.status,
      scheduledAt: scheduledAt == _sentinel
          ? this.scheduledAt
          : scheduledAt as DateTime?,
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      impressions: impressions == _sentinel
          ? this.impressions
          : impressions as int?,
      reactions: reactions == _sentinel ? this.reactions : reactions as int?,
      clicks: clicks == _sentinel ? this.clicks : clicks as int?,
      insightsFetchedAt: insightsFetchedAt == _sentinel
          ? this.insightsFetchedAt
          : insightsFetchedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'snippet': snippet,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'hasImage': hasImage,
    'localImagePaths': localImagePaths,
    // Keep the legacy key so an older build can still read the record.
    if (localImagePath != null) 'localImagePath': localImagePath,
    'permalink': permalink,
    'status': status.name,
    'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
    'pageId': pageId,
    'pageName': pageName,
    'errorMessage': errorMessage,
    'impressions': impressions,
    'reactions': reactions,
    'clicks': clicks,
    'insightsFetchedAt': insightsFetchedAt?.toUtc().toIso8601String(),
  };

  factory FacebookPostRecord.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['localImagePaths'];
    final paths = rawPaths is List
        ? rawPaths.whereType<String>().where((e) => e.isNotEmpty).toList()
        : <String>[
            if ((json['localImagePath'] as String? ?? '').isNotEmpty)
              json['localImagePath'] as String,
          ];
    return FacebookPostRecord(
      id: json['id'] as String,
      postId: json['postId'] as String,
      snippet: json['snippet'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      hasImage: json['hasImage'] as bool? ?? false,
      localImagePaths: paths,
      permalink: json['permalink'] as String? ?? '',
      status: FacebookPostStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => FacebookPostStatus.published,
      ),
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? '')
          ?.toLocal(),
      pageId: json['pageId'] as String? ?? '',
      pageName: json['pageName'] as String? ?? '',
      errorMessage: json['errorMessage'] as String?,
      impressions: (json['impressions'] as num?)?.toInt(),
      reactions: (json['reactions'] as num?)?.toInt(),
      clicks: (json['clicks'] as num?)?.toInt(),
      insightsFetchedAt: DateTime.tryParse(
        json['insightsFetchedAt'] as String? ?? '',
      )?.toLocal(),
    );
  }

  static const Object _sentinel = Object();
}
