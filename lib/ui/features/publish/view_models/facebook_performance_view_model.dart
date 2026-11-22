import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_page_insights_service.dart';
import 'package:oreamnos/data/services/facebook_page_insights_store.dart';
import 'package:oreamnos/data/services/facebook_monetization_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/domain/models/facebook_monetization.dart';
import 'package:oreamnos/domain/models/facebook_page_insights.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/domain/models/posting_time_slot.dart';
import 'package:oreamnos/domain/services/best_time_to_post.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

const _cacheTtl = Duration(minutes: 30);

class FacebookPerformanceState {
  const FacebookPerformanceState({
    this.data,
    this.monetization,
    this.loading = false,
    this.error,
    this.days = 28,
  });

  final FacebookPageInsights? data;
  final FacebookMonetizationSnapshot? monetization;
  final bool loading;
  final String? error;
  final int days;

  bool get hasData => data?.hasAny ?? false;
}

final facebookPerformanceProvider =
    NotifierProvider<FacebookPerformanceNotifier, FacebookPerformanceState>(
      FacebookPerformanceNotifier.new,
    );

class FacebookPerformanceNotifier extends Notifier<FacebookPerformanceState> {
  late final FacebookPageInsightsService _service;
  late final FacebookPageInsightsStore _store;
  late final FacebookMonetizationService _monetization;
  late final PreferencesService _prefs;
  String _pageId = '';
  int _generation = 0;

  @override
  FacebookPerformanceState build() {
    _service = getIt<FacebookPageInsightsService>();
    _store = getIt<FacebookPageInsightsStore>();
    _monetization = getIt<FacebookMonetizationService>();
    _prefs = getIt<PreferencesService>();
    _pageId = ref.read(facebookViewModelProvider).activePageId;
    final days = _prefs.facebookPerformanceDays;
    final cached = _pageId.isEmpty ? null : _store.load(_pageId, days: days);
    return FacebookPerformanceState(data: cached, days: days);
  }

  Future<void> ensureLoaded({bool force = false}) async {
    if (state.loading && !force) return;
    final cached = state.data;
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
      return;
    }
    await refresh();
  }

  Future<String?> refresh({int? days}) async {
    final requestedDays = days ?? state.days;
    await _prefs.setFacebookPerformanceDays(requestedDays);
    final pageId = ref.read(facebookViewModelProvider).activePageId;
    final pageChanged = pageId != _pageId;
    _pageId = pageId;
    final generation = ++_generation;
    if (pageId.isEmpty) {
      state = FacebookPerformanceState(
        days: requestedDays,
        error: 'Connect your Page to load performance.',
      );
      return state.error;
    }
    final token = await _prefs.getFacebookPageToken() ?? '';
    if (generation != _generation) return null;
    if (token.isEmpty) {
      state = FacebookPerformanceState(
        days: requestedDays,
        error: 'Reconnect your Page to load performance.',
      );
      return state.error;
    }
    state = FacebookPerformanceState(
      data: pageChanged ? null : state.data,
      monetization: pageChanged ? null : state.monetization,
      loading: true,
      days: requestedDays,
    );
    FacebookMonetizationSnapshot? monetization;
    final monetizationFuture = _monetization
        .fetch(pageId: pageId, token: token, days: 28)
        .then<FacebookMonetizationSnapshot?>((value) => value)
        .catchError((_) => null);
    try {
      var data = await _service.fetch(
        pageId: pageId,
        token: token,
        days: requestedDays,
      );
      monetization = await monetizationFuture;
      if (generation != _generation) return null;
      try {
        final previous = await _service.fetchPrevious(
          pageId: pageId,
          token: token,
          days: requestedDays,
        );
        if (generation != _generation) return null;
        data = data.copyWith(
          previousPoints: previous.points,
          previousUnavailableMetrics: previous.unavailableMetrics,
        );
      } catch (_) {
        // The previous window is optional; keep the current period.
      }
      await _store.save(data);
      if (generation != _generation) return null;
      state = FacebookPerformanceState(
        data: data,
        monetization: monetization,
        days: requestedDays,
      );
      return null;
    } on FacebookApiException catch (e) {
      if (generation != _generation) return null;
      if (e.needsReconnect) {
        ref.read(facebookViewModelProvider.notifier).markExpired();
      }
      state = FacebookPerformanceState(
        data: state.data,
        monetization: monetization ?? state.monetization,
        error: e.message,
        days: requestedDays,
      );
      return e.message;
    } catch (_) {
      if (generation != _generation) return null;
      const message = 'Could not load Page performance.';
      state = FacebookPerformanceState(
        data: state.data,
        monetization: monetization ?? state.monetization,
        error: message,
        days: requestedDays,
      );
      return message;
    }
  }
}

/// Deterministic suggestions from the Page's own published history.
final bestTimeToPostProvider = Provider<List<PostingTimeSlot>>((ref) {
  final records = ref.watch(facebookHistoryProvider);
  return BestTimeToPost.compute(records);
});

/// UI copy for the empty best-time state.
final bestTimeToPostReasonProvider = Provider<String?>((ref) {
  final records = ref.watch(facebookHistoryProvider);
  final slots = BestTimeToPost.compute(records);
  return slots.isEmpty ? BestTimeToPost.emptyReason(records) : null;
});

/// Newest published posts, used by the performance overview.
final recentPublishedPostsProvider = Provider<List<FacebookPostRecord>>((ref) {
  final records = ref.watch(facebookHistoryProvider);
  return records.where((r) => r.isPublished).take(5).toList(growable: false);
});

/// Posts in the selected range ranked by engagement rate, then recency.
final facebookTopPostsProvider = Provider<List<FacebookPostRecord>>((ref) {
  final days = ref.watch(facebookPerformanceProvider).days;
  final cutoff = DateTime.now().subtract(Duration(days: days));
  final records = ref
      .watch(facebookHistoryProvider)
      .where((r) => r.isPublished && r.timestamp.isAfter(cutoff))
      .toList();
  double score(FacebookPostRecord record) {
    final engagement =
        (record.reactions ?? 0) + (record.comments ?? 0) + (record.shares ?? 0);
    final reach = record.uniqueViewers ?? record.impressions;
    if (reach == null || reach <= 0) return engagement.toDouble();
    return engagement / reach * 1000;
  }

  records.sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    if (byScore != 0) return byScore;
    return b.timestamp.compareTo(a.timestamp);
  });
  return records.take(5).toList(growable: false);
});

/// Compact number formatter for the Publish hub performance card.
String compactMetric(int? value) {
  if (value == null) return '—';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return '$value';
}

/// One period-over-period metric comparison shown on the Publish hub.
class FacebookMetricDelta {
  const FacebookMetricDelta({
    required this.label,
    required this.value,
    required this.negative,
  });

  /// Metric label, e.g. 'Media views'.
  final String label;

  /// Signed, compact value, e.g. '+12.3k', '-450' or 'same'.
  final String value;

  /// True when [value] indicates a drop; widgets color it as a decrease.
  final bool negative;
}

/// Deltas between [current] and [previous] for media views and engagements.
///
/// A metric is included only when both windows have a value; a zero
/// difference reads as 'same'.
List<FacebookMetricDelta> computePerformanceDeltas({
  required FacebookInsightTotals current,
  required FacebookInsightTotals previous,
}) {
  final deltas = <FacebookMetricDelta>[];

  void addDelta(String label, int? cur, int? prev) {
    if (cur == null || prev == null) return;
    final diff = cur - prev;
    if (diff == 0) {
      deltas.add(
        FacebookMetricDelta(label: label, value: 'same', negative: false),
      );
    } else if (diff > 0) {
      deltas.add(
        FacebookMetricDelta(
          label: label,
          value: '+${compactMetric(diff)}',
          negative: false,
        ),
      );
    } else {
      deltas.add(
        FacebookMetricDelta(
          label: label,
          value: '-${compactMetric(-diff)}',
          negative: true,
        ),
      );
    }
  }

  addDelta('Media views', current.mediaViews, previous.mediaViews);
  addDelta('Engagements', current.engagements, previous.engagements);
  return deltas;
}
