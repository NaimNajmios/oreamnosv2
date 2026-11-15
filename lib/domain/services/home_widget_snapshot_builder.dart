import 'dart:convert';

import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/models/home_widget_snapshot.dart';
import 'package:oreamnos/domain/services/best_time_to_post.dart';

/// One Gemini model's daily request count, decoupled from the data-layer
/// `DailyQuota` so this domain service stays free of `data/` imports.
class HomeWidgetQuota {
  const HomeWidgetQuota({
    required this.modelId,
    required this.requestsToday,
    required this.budget,
  });

  final String modelId;
  final int requestsToday;
  final int budget;
}

/// Builds the home-screen widget payload from already-loaded app state.
///
/// Pure and clock-injected so the whole contract is unit-testable without the
/// platform channel, and so previews/tests never depend on wall-clock time.
class HomeWidgetSnapshotBuilder {
  const HomeWidgetSnapshotBuilder();

  static const int maxSnippetChars = 90;
  static const int maxDraftChars = 40;
  static const int maxBestSlotChars = 40;
  static const int maxBestSlotDetailChars = 60;
  static const int maxPageEntries = 5;

  /// `pages_json` is the one value allowed to exceed [maxPayloadChars]: it
  /// carries every Page so a widget can be configured to pin one.
  static const int maxPayloadChars = 120;
  static const int maxPagesJsonChars = 600;

  HomeWidgetSnapshot build({
    required DateTime now,
    required List<FacebookPostRecord> records,
    required List<HomeWidgetQuota> quotas,
    required String pageName,
    required bool pageConnected,
    required bool pageExpired,
    required int draftCount,
    required HomeWidgetPalette palette,
    String? selectedProviderId,
    String? selectedModel,
    DateTime? quotaResetAt,
    Map<String, List<int>> quotaHistory = const {},
    List<HomeWidgetPage> pages = const [],
    String draftTitle = '',
    bool showSnippet = false,
    HomeWidgetSecondRow secondRow = HomeWidgetSecondRow.quota,
  }) {
    final scheduled =
        records
            .where((record) => record.isScheduled && record.scheduledAt != null)
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final next = scheduled.isEmpty ? null : scheduled.first;

    final quota = _pickQuota(quotas, selectedProviderId, selectedModel);
    final lastPost = _lastEngagedPost(records);
    // Only worth naming a slot when there is nothing to count down to.
    final bestSlots = next == null
        ? BestTimeToPost.compute(records, now: now, limit: 1)
        : const [];

    return HomeWidgetSnapshot(
      updatedAt: now,
      // The caption is the most sensitive field in the payload, so it is
      // withheld unless the user opted in on a shared home screen.
      nextSnippet: showSnippet ? _clean(next?.snippet ?? '') : '',
      nextPage: next?.pageName.trim() ?? '',
      nextAt: next?.scheduledAt,
      // Scheduled records only carry the Story flag once it is known; a
      // Story-only record is the one case the widget can label confidently.
      nextIsStory: next?.isStoryOnly ?? false,
      scheduledCount: scheduled.length,
      draftCount: draftCount,
      quotaModel: quota == null ? null : _shortModel(quota.modelId),
      quotaUsed: quota?.requestsToday,
      quotaBudget: quota?.budget,
      quotaResetAt: quota == null ? null : quotaResetAt,
      quotaAverage: quota == null
          ? null
          : _averageRequests(quotaHistory, quota.modelId),
      pageName: pageName.trim(),
      pageConnected: pageConnected,
      pageExpired: pageExpired,
      palette: palette,
      secondRow: secondRow,
      lastPostSnippet: _clean(lastPost?.snippet ?? '', max: maxDraftChars),
      lastPostReactions: lastPost?.reactions,
      lastPostComments: lastPost?.comments,
      lastPostShares: lastPost?.shares,
      lastPostAt: lastPost?.timestamp,
      bestSlotLabel: bestSlots.isEmpty
          ? ''
          : _clean(bestSlots.first.label, max: maxBestSlotChars),
      bestSlotDetail: bestSlots.isEmpty
          ? ''
          : _clean(bestSlots.first.detail, max: maxBestSlotDetailChars),
      bestSlotConfident: bestSlots.isNotEmpty && bestSlots.first.confidence,
      storyFailedCount: records.where((record) => record.storyFailed).length,
      draftTitle: _clean(draftTitle, max: maxDraftChars),
      weekPostCount: _publishedThisWeek(records, now),
      pagesJson: _pagesJson(pages, scheduled, showSnippet),
    );
  }

  /// Newest published post that actually has cached engagement. Posts without
  /// metrics would render an empty row, so they are skipped.
  static FacebookPostRecord? _lastEngagedPost(
    List<FacebookPostRecord> records,
  ) {
    FacebookPostRecord? newest;
    for (final record in records) {
      if (!record.isPublished) continue;
      final hasMetrics =
          record.reactions != null ||
          record.comments != null ||
          record.shares != null;
      if (!hasMetrics) continue;
      if (newest == null || record.timestamp.isAfter(newest.timestamp)) {
        newest = record;
      }
    }
    return newest;
  }

  static int _publishedThisWeek(
    List<FacebookPostRecord> records,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    var count = 0;
    for (final record in records) {
      if (!record.isPublished) continue;
      if (record.timestamp.isBefore(startOfWeek)) continue;
      count++;
    }
    return count;
  }

  /// Mean requests per active day over the retained window. Days with no
  /// activity are excluded rather than counted as zero, which would drag the
  /// average down after a week off.
  static int? _averageRequests(Map<String, List<int>> history, String modelId) {
    final target = _normalizeModel(modelId);
    for (final entry in history.entries) {
      if (_normalizeModel(entry.key) != target) continue;
      final counts = entry.value.where((value) => value > 0).toList();
      if (counts.isEmpty) return null;
      final total = counts.fold<int>(0, (sum, value) => sum + value);
      return (total / counts.length).round();
    }
    return null;
  }

  /// Per-Page next-up, so one widget can pin a Page while another follows the
  /// active one. Capped so a home-screen payload stays small.
  static String _pagesJson(
    List<HomeWidgetPage> pages,
    List<FacebookPostRecord> scheduled,
    bool showSnippet,
  ) {
    if (pages.isEmpty) return '[]';
    final entries = <Map<String, Object>>[];
    for (final page in pages.take(maxPageEntries)) {
      FacebookPostRecord? next;
      for (final record in scheduled) {
        if (record.pageId != page.id) continue;
        next = record;
        break;
      }
      entries.add({
        'id': page.id,
        'name': page.name,
        'nextAt': next?.scheduledAt?.millisecondsSinceEpoch ?? 0,
        'snippet': showSnippet ? _clean(next?.snippet ?? '', max: 60) : '',
        'isStory': next?.isStoryOnly ?? false,
      });
    }
    final encoded = jsonEncode(entries);
    return encoded.length <= maxPagesJsonChars ? encoded : '[]';
  }

  /// The selected model's own row when Gemini is active, otherwise the busiest
  /// model of the day. Guessing a model would make the quota look wrong.
  static HomeWidgetQuota? _pickQuota(
    List<HomeWidgetQuota> quotas,
    String? selectedProviderId,
    String? selectedModel,
  ) {
    if (quotas.isEmpty) return null;

    final provider = (selectedProviderId ?? 'gemini').trim().toLowerCase();
    final model = _normalizeModel(selectedModel);
    if (provider == 'gemini' && model.isNotEmpty) {
      for (final quota in quotas) {
        if (_normalizeModel(quota.modelId) == model) return quota;
      }
    }

    var busiest = quotas.first;
    for (final quota in quotas) {
      if (quota.requestsToday > busiest.requestsToday) busiest = quota;
    }
    return busiest;
  }

  static String _normalizeModel(String? modelId) {
    var value = (modelId ?? '').trim().toLowerCase();
    if (value.startsWith('models/')) {
      value = value.substring('models/'.length);
    }
    return value;
  }

  /// `gemini-2.5-flash` → `2.5-flash`; the widget has no room for the vendor.
  static String _shortModel(String modelId) {
    final normalized = _normalizeModel(modelId);
    return normalized.startsWith('gemini-')
        ? normalized.substring('gemini-'.length)
        : normalized;
  }

  static String _clean(String value, {int max = maxSnippetChars}) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= max) return collapsed;
    return '${collapsed.substring(0, max - 1).trimRight()}…';
  }
}
