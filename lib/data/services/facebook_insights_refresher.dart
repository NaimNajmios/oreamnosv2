import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'facebook_history_service.dart';
import '../../domain/models/facebook_post_record.dart';

/// State of a [FacebookInsightsRefresher] run.
class FacebookInsightsRefreshState {
  const FacebookInsightsRefreshState({
    this.attempted = 0,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  /// Records attempted during the most recent run.
  final int attempted;

  /// Short code of the first error from the most recent run.
  final String? lastErrorCode;
  final String? lastErrorMessage;

  FacebookInsightsRefreshState copyWith({
    int? attempted,
    String? lastErrorCode,
    String? lastErrorMessage,
  }) {
    return FacebookInsightsRefreshState(
      attempted: attempted ?? this.attempted,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
    );
  }
}

/// Lazy background refresher for per-post insights.
///
/// Triggered from the Publish hub, the Facebook history screen, app resume,
/// and right after a successful publish. Stale selection is by post age, at
/// most 3 records are refreshed at a time, and the whole batch stops when a
/// `rateLimit` or reconnect-needed error comes back. Records whose latest
/// error was `permission` stay skipped until the user reconnects.
final facebookInsightsRefresherProvider =
    NotifierProvider<FacebookInsightsRefresher, FacebookInsightsRefreshState>(
      FacebookInsightsRefresher.new,
    );

class FacebookInsightsRefresher extends Notifier<FacebookInsightsRefreshState> {
  late final FacebookHistoryNotifier _history;

  @override
  FacebookInsightsRefreshState build() {
    _history = ref.read(facebookHistoryProvider.notifier);
    return const FacebookInsightsRefreshState();
  }

  bool _running = false;
  String? _lastError;
  String? _lastErrorCode;

  /// True while a [refreshStale] run is in flight.
  bool get running => _running;

  /// First real error message from the most recent run, if any.
  String? get lastError => _lastError;

  /// Short code of the first error from the most recent run (e.g.
  /// `permission`, `rateLimit`).
  String? get lastErrorCode => _lastErrorCode;

  /// Candidates: published records from the last 30 days.
  List<FacebookPostRecord> get staleCandidates {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _history.state
        .where((r) => r.isPublished && r.timestamp.isAfter(cutoff))
        .toList(growable: false);
  }

  static Duration _staleAfter(DateTime postTime) {
    final age = DateTime.now().difference(postTime);
    if (age < const Duration(days: 24)) return const Duration(minutes: 30);
    if (age < const Duration(days: 7)) return const Duration(hours: 6);
    return const Duration(hours: 24);
  }

  bool isStale(FacebookPostRecord record) {
    final last = record.lastRefreshAttemptAt ?? record.timestamp;
    return DateTime.now().difference(last) >= _staleAfter(record.timestamp);
  }

  bool _isSkipped(FacebookPostRecord record) =>
      record.insightsError == 'permission';

  /// Refreshes up to [limit] stale records, running 3 at a time.
  /// Returns the number of records attempted. A throwing worker is caught
  /// so one bad record cannot kill the batch or leave [running] stuck true.
  Future<int> refreshStale({int limit = 10}) async {
    if (_running) return 0;
    _running = true;
    _lastError = null;
    _lastErrorCode = null;
    final queue = staleCandidates
        .where((r) => !_isSkipped(r) && isStale(r))
        .toList(growable: false);
    var index = 0;
    var attempted = 0;
    var stopped = false;

    Future<void> worker() async {
      while (index < queue.length && attempted < limit && !stopped) {
        try {
          final record = queue[index];
          index++;
          attempted++;
          final summary = await _history.refreshPost(record.id);
          _lastErrorCode ??= summary.firstErrorCode;
          if (summary.firstErrorCode == 'rateLimit' ||
              summary.firstErrorCode == 'permission') {
            stopped = true;
            _lastError ??= summary.firstErrorMessage;
          } else if (_lastError == null && summary.firstErrorCode != null) {
            _lastError = summary.firstErrorMessage;
          }
        } catch (_) {
          // Defensive: never let one record crash the batch or wedge
          // _running; stop the batch since the cause is unexpected.
          stopped = true;
        }
      }
    }

    try {
      await Future.wait([worker(), worker(), worker()]);
    } catch (_) {
      stopped = true;
    } finally {
      _running = false;
    }
    state = state.copyWith(
      attempted: attempted,
      lastErrorCode: _lastErrorCode,
      lastErrorMessage: _lastError,
    );
    return attempted;
  }
}
