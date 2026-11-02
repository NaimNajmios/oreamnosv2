/// One successful publish, persisted locally (capped at 50, mirrors
/// [UsageLog]'s prefs-JSON shape). Permalink is built from `post_id` (photo
/// posts) or the object id (text posts).
class FacebookPostRecord {
  const FacebookPostRecord({
    required this.id,
    required this.postId,
    required this.snippet,
    required this.timestamp,
    required this.hasImage,
    required this.permalink,
  });

  final String id;
  final String postId;

  /// First line(s) of the plain-text message shown in the history list.
  final String snippet;
  final DateTime timestamp;
  final bool hasImage;
  final String permalink;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.month}/${timestamp.day} $h:$m';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'snippet': snippet,
    'timestamp': timestamp.toIso8601String(),
    'hasImage': hasImage,
    'permalink': permalink,
  };

  factory FacebookPostRecord.fromJson(Map<String, dynamic> json) {
    return FacebookPostRecord(
      id: json['id'] as String,
      postId: json['postId'] as String,
      snippet: json['snippet'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      hasImage: json['hasImage'] as bool? ?? false,
      permalink: json['permalink'] as String? ?? '',
    );
  }
}
