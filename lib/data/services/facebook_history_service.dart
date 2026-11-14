import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_expiry_signal.dart';
import 'package:oreamnos/data/services/facebook_diagnostics.dart';
import 'package:oreamnos/data/services/facebook_insights_service.dart';
import 'package:oreamnos/data/services/facebook_publisher_service.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/facebook_post_insights.dart';
import '../../domain/models/facebook_post_record.dart';

final facebookHistoryProvider =
    NotifierProvider<FacebookHistoryNotifier, List<FacebookPostRecord>>(
      FacebookHistoryNotifier.new,
    );

/// Outcome of a bulk Story retry.
class StoryRetrySummary {
  const StoryRetrySummary({
    required this.succeeded,
    required this.failed,
    this.firstError,
  });

  final int succeeded;
  final int failed;
  final String? firstError;

  bool get isEmpty => succeeded == 0 && failed == 0;
}

class FacebookHistoryNotifier extends Notifier<List<FacebookPostRecord>> {
  late final FacebookHistoryService _service;

  @override
  List<FacebookPostRecord> build() {
    _service = getIt<FacebookHistoryService>();
    final unsubscribe = _service.addListener((records) {
      state = records;
    });
    ref.onDispose(unsubscribe);
    return _service.records;
  }

  Future<void> remove(String id) => _service.remove(id);

  Future<void> clear() => _service.clear();

  Future<void> update(FacebookPostRecord record) => _service.update(record);

  Future<void> removeByPostId(String postId) => _service.removeByPostId(postId);

  /// Deletes a published post on Graph, then removes the local record and
  /// thumbnails. Returns a user-facing error, or null on success.
  Future<String?> deletePublishedPost(String recordId) async {
    final record = _findRecord(recordId);
    if (record == null || !record.isPublished) return null;
    final token =
        await getIt<PreferencesService>().getFacebookPageToken() ?? '';
    if (token.isEmpty) return 'Connect your Page first.';
    try {
      await getIt<FacebookPublisherService>().deletePost(
        postId: record.postId,
        token: token,
      );
      await _service.remove(recordId);
      return null;
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      return e.message;
    } catch (_) {
      return "Couldn't delete the post on Facebook. Nothing was removed.";
    }
  }

  /// Edits a published caption on Graph, then updates the local history.
  Future<String?> editPublishedPost(String recordId, String message) async {
    final record = _findRecord(recordId);
    if (record == null || !record.isPublished) return null;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return 'The caption cannot be empty.';
    if (trimmed == record.reusableCaption.trim()) return null;
    final token =
        await getIt<PreferencesService>().getFacebookPageToken() ?? '';
    if (token.isEmpty) return 'Connect your Page first.';
    try {
      await getIt<FacebookPublisherService>().updatePostMessage(
        postId: record.postId,
        token: token,
        message: message,
      );
      await _service.updateMessage(recordId, message);
      return null;
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      return e.message;
    } catch (_) {
      return "Couldn't edit the caption. Try again.";
    }
  }

  /// Retries only the Story for a record whose feed post already succeeded.
  Future<String?> retryStory(String recordId) async {
    final record = _findRecord(recordId);
    if (record == null || !record.hasStory) return null;
    if (record.storyImagePath.isEmpty ||
        !File(record.storyImagePath).existsSync()) {
      return 'The Story image is no longer available.';
    }
    final token =
        await getIt<PreferencesService>().getFacebookPageToken() ?? '';
    if (token.isEmpty) return 'Connect your Page first.';
    final pageId = record.pageId;
    if (pageId.isEmpty) return 'This record has no Page id.';
    String? photoId;
    try {
      photoId = await getIt<FacebookPublisherService>().uploadUnpublishedPhoto(
        pageId: pageId,
        token: token,
        filePath: record.storyImagePath,
        altText: record.storyTitle,
      );
      final story = await getIt<FacebookPublisherService>().publishPhotoStory(
        pageId: pageId,
        token: token,
        photoId: photoId,
      );
      await _service.update(
        record.copyWith(
          storyPostId: story.postId,
          storyStatus: FacebookStoryStatus.published,
        ),
      );
      return null;
    } on FacebookApiException catch (e) {
      if (photoId != null) {
        await getIt<FacebookPublisherService>().deletePhoto(
          photoId: photoId,
          token: token,
        );
      }
      if (e.needsReconnect) FacebookExpirySignal.report();
      return e.message;
    } catch (_) {
      return 'Could not publish the Story. Try again.';
    }
  }

  /// Retries every Story whose feed post succeeded but whose Story failed.
  /// Sequential so a burst of retries cannot trip Meta's rate limiter, and one
  /// failure does not stop the rest. Returns counts for the UI summary.
  Future<StoryRetrySummary> retryFailedStories() async {
    final failed = _service.records.where((r) => r.storyFailed).toList();
    if (failed.isEmpty) {
      return const StoryRetrySummary(succeeded: 0, failed: 0);
    }
    var succeeded = 0;
    var failedCount = 0;
    String? firstError;
    for (final record in failed) {
      final error = await retryStory(record.id);
      if (error == null) {
        succeeded++;
      } else {
        failedCount++;
        firstError ??= error;
      }
    }
    final summary = StoryRetrySummary(
      succeeded: succeeded,
      failed: failedCount,
      firstError: firstError,
    );
    FacebookDiagnostics.event(
      'Stories retried',
      detail: 'published=${summary.succeeded} failed=${summary.failed}',
    );
    return summary;
  }

  FacebookPostRecord? _findRecord(String recordId) {
    for (final item in _service.records) {
      if (item.id == recordId) return item;
    }
    return null;
  }

  /// Fetches and caches insights for one published record. Returns a
  /// user-facing error string, or null on success. Scheduled/failed records
  /// are no-ops.
  Future<String?> refreshInsights(String recordId) async {
    FacebookPostRecord? record;
    for (final item in _service.records) {
      if (item.id == recordId) {
        record = item;
        break;
      }
    }
    if (record == null || !record.isPublished) return null;
    final token =
        await getIt<PreferencesService>().getFacebookPageToken() ?? '';
    if (token.isEmpty) return 'Connect your Page first.';
    final stopwatch = Stopwatch()..start();
    try {
      final insights = await getIt<FacebookInsightsService>().fetch(
        postId: record.postId,
        token: token,
      );
      await _service.setInsights(recordId, insights);
      _log(
        'Insights refreshed in ${stopwatch.elapsedMilliseconds}ms',
        level: 'INFO',
      );
      return insights.hasAny
          ? null
          : 'Facebook has no insights for this post yet.';
    } on FacebookApiException catch (e) {
      _log(
        'Insights failed after ${stopwatch.elapsedMilliseconds}ms: ${e.message}',
        level: 'WARN',
      );
      if (e.needsReconnect) FacebookExpirySignal.report();
      return e.message;
    } catch (_) {
      _log(
        'Insights failed unexpectedly after '
        '${stopwatch.elapsedMilliseconds}ms',
        level: 'WARN',
      );
      return 'Could not load insights. Try again later.';
    }
  }

  /// Fetches stable engagement summary counts (reactions/comments/shares)
  /// independently from insights metrics, so a retired insight metric can
  /// never hide the badges.
  Future<String?> refreshEngagement(String recordId) async {
    FacebookPostRecord? record;
    for (final item in _service.records) {
      if (item.id == recordId) {
        record = item;
        break;
      }
    }
    if (record == null || !record.isPublished) return null;
    final token =
        await getIt<PreferencesService>().getFacebookPageToken() ?? '';
    if (token.isEmpty) return 'Connect your Page first.';
    final stopwatch = Stopwatch()..start();
    try {
      final engagement = await getIt<FacebookInsightsService>().fetchEngagement(
        postId: record.postId,
        token: token,
      );
      await _service.setInsights(recordId, engagement, engagementOnly: true);
      _log(
        'Engagement refreshed in ${stopwatch.elapsedMilliseconds}ms',
        level: 'INFO',
      );
      return null;
    } on FacebookApiException catch (e) {
      _log(
        'Engagement failed after ${stopwatch.elapsedMilliseconds}ms: '
        '${e.message}',
        level: 'WARN',
      );
      if (e.needsReconnect) FacebookExpirySignal.report();
      return e.message;
    } catch (_) {
      _log(
        'Engagement failed unexpectedly after '
        '${stopwatch.elapsedMilliseconds}ms',
        level: 'WARN',
      );
      return 'Could not load engagement. Try again later.';
    }
  }

  void _log(String message, {required String level}) {
    if (!getIt.isRegistered<LogService>()) return;
    final service = getIt<LogService>();
    if (level == 'WARN') {
      service.warning(message, tag: 'Facebook');
    } else {
      service.info(message, tag: 'Facebook');
    }
  }
}

/// Persisted publish history (newest first, capped at 50 — the same ring
/// behaviour as `UsageService`). Backed by prefs so the list and the
/// Published Posts settings tile survive restarts.
@lazySingleton
class FacebookHistoryService {
  static const int _maxRecords = 50;

  final SharedPreferences _prefs;
  List<FacebookPostRecord> _records = [];
  final List<void Function(List<FacebookPostRecord>)> _listeners = [];

  FacebookHistoryService(this._prefs) {
    _load();
  }

  void Function() addListener(
    void Function(List<FacebookPostRecord>) listener,
  ) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener(records);
    }
  }

  List<FacebookPostRecord> get records => List.unmodifiable(_records);

  void _load() {
    try {
      final list = _prefs.getStringList(AppConstants.keyFacebookHistory) ?? [];
      _records = list
          .map((e) => FacebookPostRecord.fromJson(jsonDecode(e)))
          .toList();
    } catch (_) {
      _records = [];
    }
    _notify();
  }

  Future<void> _persist() async {
    try {
      await _prefs.setStringList(
        AppConstants.keyFacebookHistory,
        _records.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (_) {}
  }

  /// Adds a successful publish/schedule. Returns the created record.
  Future<FacebookPostRecord> recordPublish({
    required String postId,
    required String message,
    required String permalink,
    required bool hasImage,
    String? sourceImagePath,
    List<String> sourceImagePaths = const [],
    FacebookPostStatus status = FacebookPostStatus.published,
    DateTime? scheduledAt,
    String pageId = '',
    String pageName = '',
    List<Map<String, dynamic>> mediaMetadata = const [],
    String storyPostId = '',
    String storyUrl = '',
    FacebookStoryStatus storyStatus = FacebookStoryStatus.none,
    String storyTitle = '',
    String storyImagePath = '',
    String workflowId = '',
    String workflowName = '',
    bool isStoryOnly = false,
  }) async {
    final snippet = message.trim().isEmpty
        ? (hasImage ? 'Card post' : 'Text post')
        : message.trim().split('\n').first;
    final id = const Uuid().v4();
    final sources = <String>[
      ...sourceImagePaths.where((p) => p.isNotEmpty),
      if (sourceImagePath != null && sourceImagePath.isNotEmpty)
        sourceImagePath,
    ];
    final thumbnails = <String>[];
    if (hasImage) {
      for (final source in sources) {
        final copied = await _copyThumbnail(source, '$id-${thumbnails.length}');
        if (copied != null) thumbnails.add(copied);
      }
    }
    final storedStoryPath = storyImagePath.isEmpty
        ? ''
        : await _copyThumbnail(storyImagePath, '$id-story') ?? storyImagePath;
    final record = FacebookPostRecord(
      id: id,
      postId: postId,
      snippet: snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet,
      message: message,
      timestamp: DateTime.now(),
      hasImage: hasImage,
      localImagePaths: thumbnails,
      permalink: permalink,
      status: status,
      scheduledAt: scheduledAt,
      pageId: pageId,
      pageName: pageName,
      mediaMetadata: mediaMetadata,
      storyPostId: storyPostId,
      storyUrl: storyUrl,
      storyStatus: storyStatus,
      storyTitle: storyTitle,
      storyImagePath: storedStoryPath,
      workflowId: workflowId,
      workflowName: workflowName,
      isStoryOnly: isStoryOnly,
    );
    _records = List.of(_records)..insert(0, record);
    if (_records.length > _maxRecords) {
      final evicted = _records.sublist(_maxRecords);
      _records = _records.sublist(0, _maxRecords);
      for (final old in evicted) {
        for (final path in old.localImagePaths) {
          await _deleteQuietly(path);
        }
        await _deleteQuietly(old.storyImagePath);
      }
    }
    await _persist();
    _notify();
    return record;
  }

  /// Updates the caption of a published record and refreshes its snippet.
  Future<void> updateMessage(String id, String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    final index = _records.indexWhere((r) => r.id == id);
    if (index < 0) return;
    final line = trimmed.split('\n').first;
    _records = List.of(_records)
      ..[index] = _records[index].copyWith(
        message: message,
        snippet: line.length > 140 ? '${line.substring(0, 140)}…' : line,
        editedAt: DateTime.now(),
      );
    await _persist();
    _notify();
  }

  Future<void> update(FacebookPostRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index < 0) return;
    _records = List.of(_records)..[index] = record;
    await _persist();
    _notify();
  }

  /// Caches fetched insights on a record. Null metrics never wipe an
  /// existing cached value. Engagement-only refreshes do not move the
  /// insights timestamp.
  Future<void> setInsights(
    String id,
    FacebookPostInsights insights, {
    bool engagementOnly = false,
  }) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index < 0) return;
    var updated = _records[index];
    if (insights.impressions != null) {
      updated = updated.copyWith(impressions: insights.impressions);
    }
    if (insights.reactions != null) {
      updated = updated.copyWith(reactions: insights.reactions);
    }
    if (insights.clicks != null) {
      updated = updated.copyWith(clicks: insights.clicks);
    }
    if (insights.totalImpressions != null) {
      updated = updated.copyWith(totalImpressions: insights.totalImpressions);
    }
    if (insights.engagedUsers != null) {
      updated = updated.copyWith(engagedUsers: insights.engagedUsers);
    }
    if (insights.negativeFeedback != null) {
      updated = updated.copyWith(negativeFeedback: insights.negativeFeedback);
    }
    if (insights.reactionsByType != null) {
      updated = updated.copyWith(reactionsByType: insights.reactionsByType);
    }
    if (insights.uniqueViewers != null) {
      updated = updated.copyWith(uniqueViewers: insights.uniqueViewers);
    }
    if (insights.comments != null) {
      updated = updated.copyWith(comments: insights.comments);
    }
    if (insights.shares != null) {
      updated = updated.copyWith(shares: insights.shares);
    }
    if (insights.activityByActionType != null) {
      updated = updated.copyWith(
        activityByActionType: insights.activityByActionType,
      );
    }
    final hasEngagement =
        insights.reactions != null ||
        insights.comments != null ||
        insights.shares != null;
    if (hasEngagement) {
      updated = updated.copyWith(engagementFetchedAt: insights.fetchedAt);
    }
    if (!engagementOnly && insights.hasAny) {
      updated = updated.copyWith(insightsFetchedAt: insights.fetchedAt);
    }
    _records = List.of(_records)..[index] = updated;
    await _persist();
    _notify();
  }

  Future<void> remove(String id) async {
    FacebookPostRecord? removed;
    for (final record in _records) {
      if (record.id == id) {
        removed = record;
        break;
      }
    }
    _records = List.of(_records)..removeWhere((r) => r.id == id);
    if (removed != null) {
      for (final path in removed.localImagePaths) {
        await _deleteQuietly(path);
      }
      await _deleteQuietly(removed.storyImagePath);
    }
    await _persist();
    _notify();
  }

  /// Removes the record(s) created for a Graph post id (cancel flow).
  Future<void> removeByPostId(String postId) async {
    final matches = _records.where((r) => r.postId == postId).toList();
    if (matches.isEmpty) return;
    _records = List.of(_records)..removeWhere((r) => r.postId == postId);
    for (final record in matches) {
      for (final path in record.localImagePaths) {
        await _deleteQuietly(path);
      }
      await _deleteQuietly(record.storyImagePath);
    }
    await _persist();
    _notify();
  }

  Future<void> clear() async {
    for (final record in _records) {
      for (final path in record.localImagePaths) {
        await _deleteQuietly(path);
      }
      await _deleteQuietly(record.storyImagePath);
    }
    _records = [];
    await _prefs.remove(AppConstants.keyFacebookHistory);
    _notify();
  }

  /// Copies the published image into app documents before the OS purges the
  /// composer's temp file. Best-effort: a failure leaves the record without
  /// a thumbnail.
  Future<String?> _copyThumbnail(String sourcePath, String id) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/facebook_thumbs');
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final extension = _extensionOf(sourcePath);
      final target = File('${dir.path}/$id$extension');
      await File(sourcePath).copy(target.path);
      return target.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '.png';
    final ext = path.substring(dot);
    return ext.length <= 5 ? ext : '.png';
  }
}
