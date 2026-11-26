import 'dart:convert';

import 'package:oreamnos/domain/models/facebook_page_insights.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/models/home_widget_snapshot.dart';
import 'package:oreamnos/domain/services/best_time_to_post.dart';

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

  /// `pages_json` and `quota_json` are the values allowed to exceed
  /// [maxPayloadChars]: one carries every Page so a widget can pin one, the
  /// other every provider so the quota widget can show two side by side.
  static const int maxPayloadChars = 120;
  static const int maxPagesJsonChars = 600;
  static const int maxQuotaJsonChars = 600;

  HomeWidgetSnapshot build({
    required DateTime now,
    required List<FacebookPostRecord> records,
    required List<HomeWidgetQuota> quotas,
    required String pageName,
    required bool pageConnected,
    required bool pageExpired,
    required int draftCount,
    required HomeWidgetPalette palette,
    String activeProvider = 'gemini',
    String fallbackProvider = 'groq',
    List<HomeWidgetPage> pages = const [],
    String draftTitle = '',
    List<String> draftTitles = const [],
    DateTime? draftUpdatedAt,
    bool showSnippet = false,
    double warnFraction = 0.8,
    FacebookPageInsights? pageInsights,
    int pageRangeDays = 28,
  }) {
    final scheduled =
        records
            .where((record) => record.isScheduled && record.scheduledAt != null)
            .toList()
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final next = scheduled.isEmpty ? null : scheduled.first;

    final lastPost = _lastEngagedPost(records);
    // Only worth naming a slot when there is nothing to count down to.
    final bestSlots = next == null
        ? BestTimeToPost.compute(records, now: now, limit: 1)
        : const [];
    final week = _weekEngagement(records, now);
    final quotaJson = _quotaJson(quotas, warnFraction);
    final lastPublished = _lastPublishedPost(records);
    final pageMetrics = _pageMetrics(pageInsights);

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
      quotaJson: quotaJson,
      quotaResetAt: _nextQuotaReset(quotas, now),
      pageName: pageName.trim(),
      pageConnected: pageConnected,
      pageExpired: pageExpired,
      palette: palette,
      activeProvider: activeProvider,
      fallbackProvider: fallbackProvider,
      lastPostSnippet: _clean(lastPost?.snippet ?? '', max: maxDraftChars),
      lastPostReactions: lastPost?.reactions,
      lastPostComments: lastPost?.comments,
      lastPostShares: lastPost?.shares,
      lastPostImpressions: lastPost?.impressions,
      lastPostUniqueViewers: lastPost?.uniqueViewers,
      lastPostAt: lastPost?.timestamp,
      weekReactions: week.reactions,
      weekComments: week.comments,
      weekShares: week.shares,
      bestSlotLabel: bestSlots.isEmpty
          ? ''
          : _clean(bestSlots.first.label, max: maxBestSlotChars),
      bestSlotDetail: bestSlots.isEmpty
          ? ''
          : _clean(bestSlots.first.detail, max: maxBestSlotDetailChars),
      bestSlotConfident: bestSlots.isNotEmpty && bestSlots.first.confidence,
      bestSlotNextAt: bestSlots.isEmpty
          ? null
          : BestTimeToPost.nextOccurrence(bestSlots.first, now: now),
      bestSlotSamples: bestSlots.isEmpty ? 0 : bestSlots.first.sampleSize,
      storyFailedCount: records.where((record) => record.storyFailed).length,
      draftTitle: _clean(draftTitle, max: maxDraftChars),
      draftTitlesJson: _draftTitlesJson(draftTitles),
      draftUpdatedAt: draftUpdatedAt,
      weekPostCount: _publishedThisWeek(records, now),
      pagesJson: _pagesJson(pages, scheduled, showSnippet),
      lastPublishedAt: lastPublished == null
          ? null
          : _effectivePostTime(lastPublished),
      pageViews: pageMetrics.views,
      pageEngagements: pageMetrics.engagements,
      pageFollows: pageMetrics.follows,
      pageViewsDelta: pageMetrics.viewsDelta,
      pageEngagementsDelta: pageMetrics.engagementsDelta,
      pageRangeDays: pageRangeDays,
      pageInsightsAt: pageInsights?.fetchedAt,
    );
  }

  /// A scheduled post's `timestamp` is the moment the record was created, not
  /// when it went live (`recordPublish` stamps `DateTime.now()` at scheduling
  /// time). Use the scheduled instant whenever one exists so "time since my
  /// last post" is not inflated by the scheduling lead time.
  static DateTime _effectivePostTime(FacebookPostRecord record) =>
      record.scheduledAt ?? record.timestamp;

  /// The most recent post that actually went live, whether or not its
  /// engagement has ever been fetched. A freshly published post is precisely
  /// the one the engagement widget cannot see yet.
  static FacebookPostRecord? _lastPublishedPost(
    List<FacebookPostRecord> records,
  ) {
    FacebookPostRecord? newest;
    DateTime? newestAt;
    for (final record in records) {
      if (!record.isPublished) continue;
      final at = _effectivePostTime(record);
      if (newestAt == null || at.isAfter(newestAt)) {
        newest = record;
        newestAt = at;
      }
    }
    return newest;
  }

  /// Reduces the cached Page snapshot to widget-sized values. Deltas need both
  /// windows; a missing previous period is omitted rather than shown as zero.
  static _PageMetrics _pageMetrics(FacebookPageInsights? insights) {
    if (insights == null) return const _PageMetrics();
    final current = insights.currentTotals;
    final previous = insights.previousTotals;
    return _PageMetrics(
      views: current.mediaViews,
      engagements: current.engagements,
      follows: current.follows,
      viewsDelta: _signedCompact(current.mediaViews, previous.mediaViews),
      engagementsDelta: _signedCompact(
        current.engagements,
        previous.engagements,
      ),
    );
  }

  static String? _signedCompact(int? current, int? previous) {
    if (current == null || previous == null) return null;
    final diff = current - previous;
    if (diff == 0) return 'same';
    return diff > 0 ? '+${_compact(diff)}' : '-${_compact(-diff)}';
  }

  /// Mirrors the Publish hub's compact formatting so the widget and the app
  /// read the same way. Kept local to avoid a domain → UI import.
  static String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }

  /// Encoded for the quota widget. Entries are dropped from the end until the
  /// array fits, so a future provider can never overflow the payload — the
  /// widget shows fewer slots instead of failing to parse.
  static String _quotaJson(List<HomeWidgetQuota> quotas, double warnFraction) {
    final entries = quotas.take(4).toList();
    while (entries.isNotEmpty) {
      final encoded = HomeWidgetQuota.encodeAll(entries, warnFraction);
      if (encoded.length <= maxQuotaJsonChars) return encoded;
      entries.removeLast();
    }
    return '[]';
  }

  /// The earliest reset among providers with a known budget; it is the only
  /// quota event that can change what a widget shows without the app running.
  static DateTime? _nextQuotaReset(List<HomeWidgetQuota> quotas, DateTime now) {
    DateTime? earliest;
    for (final quota in quotas) {
      final reset = quota.resetAt;
      if (!quota.hasBudget || reset == null || !reset.isAfter(now)) continue;
      if (earliest == null || reset.isBefore(earliest)) earliest = reset;
    }
    return earliest;
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
          record.shares != null ||
          record.impressions != null ||
          record.uniqueViewers != null;
      if (!hasMetrics) continue;
      if (newest == null || record.timestamp.isAfter(newest.timestamp)) {
        newest = record;
      }
    }
    return newest;
  }

  static const _WeekEngagement _emptyWeek = _WeekEngagement(0, 0, 0);

  static _WeekEngagement _weekEngagement(
    List<FacebookPostRecord> records,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    var reactions = 0;
    var comments = 0;
    var shares = 0;
    var any = false;
    for (final record in records) {
      if (!record.isPublished) continue;
      if (record.timestamp.isBefore(startOfWeek)) continue;
      any = true;
      reactions += record.reactions ?? 0;
      comments += record.comments ?? 0;
      shares += record.shares ?? 0;
    }
    return any ? _WeekEngagement(reactions, comments, shares) : _emptyWeek;
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

  /// Two drafts are enough for the widget's continuation line; more would
  /// crowd a home screen and inflate the payload for no benefit.
  static String _draftTitlesJson(List<String> titles) {
    final cleaned = <String>[];
    for (final title in titles.take(2)) {
      final value = _clean(title, max: maxDraftChars);
      if (value.isNotEmpty) cleaned.add(value);
    }
    return jsonEncode(cleaned);
  }

  static String _clean(String value, {int max = maxSnippetChars}) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= max) return collapsed;
    return '${collapsed.substring(0, max - 1).trimRight()}…';
  }
}

class _PageMetrics {
  const _PageMetrics({
    this.views,
    this.engagements,
    this.follows,
    this.viewsDelta,
    this.engagementsDelta,
  });

  final int? views;
  final int? engagements;
  final int? follows;
  final String? viewsDelta;
  final String? engagementsDelta;
}

class _WeekEngagement {
  const _WeekEngagement(this.reactions, this.comments, this.shares);

  final int reactions;
  final int comments;
  final int shares;
}
