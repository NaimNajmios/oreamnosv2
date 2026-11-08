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
  });

  final FacebookPageInsights? data;
  final FacebookMonetizationSnapshot? monetization;
  final bool loading;
  final String? error;

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

  @override
  FacebookPerformanceState build() {
    _service = getIt<FacebookPageInsightsService>();
    _store = getIt<FacebookPageInsightsStore>();
    _monetization = getIt<FacebookMonetizationService>();
    _prefs = getIt<PreferencesService>();
    _pageId = ref.read(facebookViewModelProvider).activePageId;
    final cached = _pageId.isEmpty ? null : _store.load(_pageId);
    return FacebookPerformanceState(data: cached);
  }

  Future<void> ensureLoaded({bool force = false}) async {
    if (state.loading) return;
    final cached = state.data;
    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
      return;
    }
    await refresh();
  }

  Future<String?> refresh() async {
    final pageId = ref.read(facebookViewModelProvider).activePageId;
    if (pageId.isEmpty) {
      state = const FacebookPerformanceState(
        error: 'Connect your Page to load performance.',
      );
      return state.error;
    }
    final token = await _prefs.getFacebookPageToken() ?? '';
    if (token.isEmpty) {
      state = const FacebookPerformanceState(
        error: 'Reconnect your Page to load performance.',
      );
      return state.error;
    }
    state = FacebookPerformanceState(
      data: state.data,
      monetization: state.monetization,
      loading: true,
    );
    FacebookMonetizationSnapshot? monetization;
    try {
      monetization = await _monetization.fetch(
        pageId: pageId,
        token: token,
        days: 28,
      );
    } catch (_) {
      // Earnings are optional; a failure must not hide performance.
      monetization = state.monetization;
    }
    try {
      final data = await _service.fetch(pageId: pageId, token: token, days: 28);
      await _store.save(data);
      state = FacebookPerformanceState(data: data, monetization: monetization);
      return null;
    } on FacebookApiException catch (e) {
      state = FacebookPerformanceState(
        data: state.data,
        monetization: monetization,
        error: e.message,
      );
      return e.message;
    } catch (_) {
      const message = 'Could not load Page performance.';
      state = FacebookPerformanceState(
        data: state.data,
        monetization: monetization,
        error: message,
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
