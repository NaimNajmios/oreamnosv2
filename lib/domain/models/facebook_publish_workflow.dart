/// Where the Story image comes from.
enum FacebookStoryPhotoSource { cover, first, generated }

/// Where the Story title comes from.
enum FacebookStoryTitleSource { firstLine, headline, custom }

/// A reusable publishing configuration: feed, Story, or both.
class FacebookPublishWorkflow {
  const FacebookPublishWorkflow({
    required this.id,
    required this.name,
    this.pageId = '',
    this.publishFeed = true,
    this.storyEnabled = false,
    this.storyPhotoSource = FacebookStoryPhotoSource.cover,
    this.storyTitleSource = FacebookStoryTitleSource.firstLine,
    this.customTitle = '',
    this.updatedAt,
    this.builtIn = false,
  });

  final String id;
  final String name;

  /// Empty = any Page; otherwise the workflow is scoped to this Page.
  final String pageId;
  final bool publishFeed;
  final bool storyEnabled;
  final FacebookStoryPhotoSource storyPhotoSource;
  final FacebookStoryTitleSource storyTitleSource;
  final String customTitle;
  final DateTime? updatedAt;
  final bool builtIn;

  bool get isEmptyDestination => !publishFeed && !storyEnabled;

  String get destinationLabel {
    if (publishFeed && storyEnabled) return 'Page + Story';
    if (publishFeed) return 'Page post';
    if (storyEnabled) return 'Story';
    return 'No destination';
  }

  FacebookPublishWorkflow copyWith({
    String? name,
    String? pageId,
    bool? publishFeed,
    bool? storyEnabled,
    FacebookStoryPhotoSource? storyPhotoSource,
    FacebookStoryTitleSource? storyTitleSource,
    String? customTitle,
    DateTime? updatedAt,
  }) {
    return FacebookPublishWorkflow(
      id: id,
      name: name ?? this.name,
      pageId: pageId ?? this.pageId,
      publishFeed: publishFeed ?? this.publishFeed,
      storyEnabled: storyEnabled ?? this.storyEnabled,
      storyPhotoSource: storyPhotoSource ?? this.storyPhotoSource,
      storyTitleSource: storyTitleSource ?? this.storyTitleSource,
      customTitle: customTitle ?? this.customTitle,
      updatedAt: updatedAt ?? this.updatedAt,
      builtIn: builtIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pageId': pageId,
    'publishFeed': publishFeed,
    'storyEnabled': storyEnabled,
    'storyPhotoSource': storyPhotoSource.name,
    'storyTitleSource': storyTitleSource.name,
    'customTitle': customTitle,
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };

  factory FacebookPublishWorkflow.fromJson(Map<String, dynamic> json) {
    return FacebookPublishWorkflow(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Workflow',
      pageId: json['pageId']?.toString() ?? '',
      publishFeed: json['publishFeed'] as bool? ?? true,
      storyEnabled: json['storyEnabled'] as bool? ?? false,
      storyPhotoSource: FacebookStoryPhotoSource.values.firstWhere(
        (s) => s.name == json['storyPhotoSource'],
        orElse: () => FacebookStoryPhotoSource.cover,
      ),
      storyTitleSource: FacebookStoryTitleSource.values.firstWhere(
        (s) => s.name == json['storyTitleSource'],
        orElse: () => FacebookStoryTitleSource.firstLine,
      ),
      customTitle: json['customTitle']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')
          ?.toLocal(),
    );
  }

  static const List<FacebookPublishWorkflow> builtIns = [
    FacebookPublishWorkflow(
      id: 'builtin-feed',
      name: 'Page post',
      builtIn: true,
    ),
    FacebookPublishWorkflow(
      id: 'builtin-feed-story',
      name: 'Page + Story',
      storyEnabled: true,
      builtIn: true,
    ),
    FacebookPublishWorkflow(
      id: 'builtin-story',
      name: 'Story only',
      publishFeed: false,
      storyEnabled: true,
      builtIn: true,
    ),
  ];
}
