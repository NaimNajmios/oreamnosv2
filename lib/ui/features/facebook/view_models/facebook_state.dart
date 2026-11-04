import 'dart:ui' show Offset;

import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

/// Connection + publishing state for the Facebook feature.
///
/// Seeded synchronously from prefs in `FacebookNotifier.build` (async
/// secure-storage reads refresh it right after), following the plain
/// `SettingsState` convention — no codegen needed here.
enum FacebookConnectionStatus {
  /// No token stored.
  notConnected,

  /// Token + Page identity persisted and assumed valid.
  connected,

  /// A publish call hit a 190 — publish UI should push a reconnect.
  expired,
}

class FacebookUiState {
  const FacebookUiState({
    this.status = FacebookConnectionStatus.notConnected,
    this.pageId = '',
    this.pageName = '',
    this.pagePictureUrl = '',
    this.pages = const [],
    this.activePageId = '',
  });

  final FacebookConnectionStatus status;
  final String pageId;
  final String pageName;
  final String pagePictureUrl;

  /// Every connected Page (identity only — tokens live in secure storage).
  final List<FacebookPage> pages;
  final String activePageId;

  bool get isConnected => status == FacebookConnectionStatus.connected;
  bool get isNotConnected => status == FacebookConnectionStatus.notConnected;
  bool get isExpired => status == FacebookConnectionStatus.expired;
  bool get hasMultiplePages => pages.length > 1;

  FacebookPage? get activePage {
    for (final page in pages) {
      if (page.id == activePageId) return page;
    }
    return null;
  }

  /// Settings-tile / compose-chip subtitle copy.
  String get subtitle {
    return switch (status) {
      FacebookConnectionStatus.connected => 'Connected · $pageName',
      FacebookConnectionStatus.expired => 'Token expired — reconnect your Page',
      FacebookConnectionStatus.notConnected => 'Not connected',
    };
  }

  FacebookUiState copyWith({
    FacebookConnectionStatus? status,
    String? pageId,
    String? pageName,
    String? pagePictureUrl,
    List<FacebookPage>? pages,
    String? activePageId,
  }) {
    return FacebookUiState(
      status: status ?? this.status,
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      pagePictureUrl: pagePictureUrl ?? this.pagePictureUrl,
      pages: pages ?? this.pages,
      activePageId: activePageId ?? this.activePageId,
    );
  }
}

/// Draft lifecycle for the compose screen.
enum FacebookComposePhase {
  /// Editing text/attachment.
  editing,

  /// Publish call in flight (includes photo preparation/upload).
  publishing,

  /// Post created — success panel shows the permalink.
  published,

  /// Scheduled — no permalink yet; success panel shows the schedule time.
  scheduled,

  /// Last publish attempt failed; [FacebookComposeState.error] holds why.
  publishError,
}

/// Whether the CTA posts now or schedules the post.
enum FacebookPublishMode { now, scheduled }

/// Feed crop presets for the attached photo. The preview shows this exact
/// frame and `FacebookImageCropper` bakes it into the uploaded file, so what
/// the composer shows is what the Page publishes.
enum FacebookImageAspect {
  landscape(ratio: 1.91, label: 'Feed', detail: '1.91:1'),
  square(ratio: 1.0, label: 'Square', detail: '1:1'),
  portrait(ratio: 0.8, label: 'Portrait', detail: '4:5');

  const FacebookImageAspect({
    required this.ratio,
    required this.label,
    required this.detail,
  });

  /// width / height.
  final double ratio;
  final String label;
  final String detail;

  static FacebookImageAspect fromName(String? name) {
    return FacebookImageAspect.values.firstWhere(
      (a) => a.name == name,
      orElse: () => FacebookImageAspect.portrait,
    );
  }
}

/// Product caps for the composer.
abstract final class FacebookLimits {
  /// Graph allows 10 per post; the product cap keeps the carousel simple.
  static const int maxPhotos = 4;
  static const int maxAltTextLength = 420;
}

/// One attached photo. A list is used from v10 on even though the composer
/// currently allows a single image, so the multi-photo phase needs no state
/// migration.
class FacebookMediaItem {
  const FacebookMediaItem({
    this.id = '',
    required this.path,
    this.aspect = FacebookImageAspect.portrait,
    this.zoom = 1.0,
    this.offset = Offset.zero,
    this.altText = '',
  });

  /// Stable per-draft identity for carousel keys and reorder/remove.
  final String id;
  final String path;
  final FacebookImageAspect aspect;

  /// 1..4. Values above 1 enable panning within the aspect frame.
  final double zoom;

  /// Normalized -1..1 panning, center = zero.
  final Offset offset;
  final String altText;

  /// Identity fallback for v10 JSON that predates media ids.
  String get identity => id.isEmpty ? path : id;

  FacebookMediaItem copyWith({
    String? id,
    String? path,
    FacebookImageAspect? aspect,
    double? zoom,
    Offset? offset,
    String? altText,
  }) {
    return FacebookMediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      aspect: aspect ?? this.aspect,
      zoom: zoom ?? this.zoom,
      offset: offset ?? this.offset,
      altText: altText ?? this.altText,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'aspect': aspect.name,
    'zoom': zoom,
    'offsetX': offset.dx,
    'offsetY': offset.dy,
    'altText': altText,
  };

  factory FacebookMediaItem.fromJson(Map<String, dynamic> json) {
    return FacebookMediaItem(
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
      aspect: FacebookImageAspect.fromName(json['aspect'] as String?),
      zoom: (json['zoom'] as num?)?.toDouble().clamp(1.0, 4.0) ?? 1.0,
      offset: Offset(
        ((json['offsetX'] as num?)?.toDouble() ?? 0).clamp(-1.0, 1.0),
        ((json['offsetY'] as num?)?.toDouble() ?? 0).clamp(-1.0, 1.0),
      ),
      altText: json['altText'] as String? ?? '',
    );
  }
}

class FacebookComposeState {
  const FacebookComposeState({
    this.text = '',
    this.media = const [],
    this.publishMode = FacebookPublishMode.now,
    this.scheduledAt,
    this.phase = FacebookComposePhase.editing,
    this.uploadProgress,
    this.result,
    this.error,
    this.restoredFromStorage = false,
  });

  /// Plain text ready for the feed (markdown already stripped at
  /// `startDraft`); the user may have edited it further.
  final String text;
  final List<FacebookMediaItem> media;
  final FacebookPublishMode publishMode;
  final DateTime? scheduledAt;
  final FacebookComposePhase phase;

  /// 0..1 while the photo multipart upload is in flight.
  final double? uploadProgress;
  final FacebookPublishResult? result;
  final FacebookApiException? error;

  /// True when `build()` restored an autosaved draft (one-shot UI hint).
  final bool restoredFromStorage;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasImage => media.isNotEmpty;
  bool get canAddMoreMedia => media.length < FacebookLimits.maxPhotos;
  bool get hasMultipleMedia => media.length > 1;

  FacebookMediaItem? mediaById(String id) {
    for (final item in media) {
      if (item.identity == id) return item;
    }
    return null;
  }

  /// Convenience for the single-photo composer.
  String? get imagePath => media.isEmpty ? null : media.first.path;
  FacebookMediaItem? get mediaItem => media.isEmpty ? null : media.first;
  FacebookImageAspect get imageAspect =>
      media.isEmpty ? FacebookImageAspect.portrait : media.first.aspect;

  bool get isPublishing => phase == FacebookComposePhase.publishing;
  bool get isPublished => phase == FacebookComposePhase.published;
  bool get isScheduled => phase == FacebookComposePhase.scheduled;
  bool get isFinished => isPublished || isScheduled;

  /// Gate for the Post/Schedule button. Time validation lives in the
  /// notifier (`publish` rejects past/immediate times with a message).
  bool get canPublish {
    if (!hasText || isPublishing || isFinished) return false;
    if (publishMode == FacebookPublishMode.scheduled) {
      return scheduledAt != null && scheduledAt!.isAfter(DateTime.now());
    }
    return true;
  }

  FacebookComposeState copyWith({
    String? text,
    Object? media = _sentinel,
    FacebookPublishMode? publishMode,
    Object? scheduledAt = _sentinel,
    FacebookComposePhase? phase,
    Object? uploadProgress = _sentinel,
    Object? result = _sentinel,
    Object? error = _sentinel,
    bool? restoredFromStorage,
  }) {
    return FacebookComposeState(
      text: text ?? this.text,
      media: media == _sentinel
          ? this.media
          : List.unmodifiable(media as List<FacebookMediaItem>),
      publishMode: publishMode ?? this.publishMode,
      scheduledAt: scheduledAt == _sentinel
          ? this.scheduledAt
          : scheduledAt as DateTime?,
      phase: phase ?? this.phase,
      uploadProgress: uploadProgress == _sentinel
          ? this.uploadProgress
          : uploadProgress as double?,
      result: result == _sentinel
          ? this.result
          : result as FacebookPublishResult?,
      error: error == _sentinel ? this.error : error as FacebookApiException?,
      restoredFromStorage: restoredFromStorage ?? this.restoredFromStorage,
    );
  }

  static const Object _sentinel = Object();
}

/// JSON shape for the autosaved draft (prefs). Image paths pointing at
/// purged temp files are still accepted here — the publish pre-flight and
/// the preview's `errorBuilder` handle that case.
class FacebookDraftSnapshot {
  const FacebookDraftSnapshot({
    required this.text,
    this.media = const [],
    this.publishMode = FacebookPublishMode.now,
    this.scheduledAt,
  });

  final String text;
  final List<FacebookMediaItem> media;
  final FacebookPublishMode publishMode;
  final DateTime? scheduledAt;

  bool get isEmpty =>
      text.trim().isEmpty && media.every((item) => item.path.isEmpty);

  Map<String, dynamic> toJson() => {
    'text': text,
    'media': media.map((item) => item.toJson()).toList(),
    'mode': publishMode.name,
    'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
  };

  factory FacebookDraftSnapshot.fromJson(Map<String, dynamic> json) {
    // v9 drafts stored a single `imagePath` + `aspect`; migrate transparently.
    final rawMedia = json['media'];
    final media = rawMedia is List
        ? rawMedia
              .whereType<Map>()
              .map((e) => FacebookMediaItem.fromJson(e.cast<String, dynamic>()))
              .toList()
        : <FacebookMediaItem>[
            if ((json['imagePath'] as String? ?? '').isNotEmpty)
              FacebookMediaItem(
                path: json['imagePath'] as String,
                aspect: FacebookImageAspect.fromName(json['aspect'] as String?),
              ),
          ];

    return FacebookDraftSnapshot(
      text: json['text'] as String? ?? '',
      media: media,
      publishMode: json['mode'] == FacebookPublishMode.scheduled.name
          ? FacebookPublishMode.scheduled
          : FacebookPublishMode.now,
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? '')
          ?.toLocal(),
    );
  }
}
