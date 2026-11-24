import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_insights_refresher.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';

/// A history notifier whose [refreshPost] throws for one id, so the
/// refresher's defensive guard can be exercised without a network.
class _ThrowingHistory extends FacebookHistoryNotifier {
  _ThrowingHistory(this.records);

  final List<FacebookPostRecord> records;
  static const _throwFor = 'boom';
  int calls = 0;

  @override
  List<FacebookPostRecord> build() => records;

  @override
  Future<FacebookPostRefreshSummary> refreshPost(String recordId) async {
    calls += 1;
    if (recordId == _throwFor) throw StateError('boom');
    return const FacebookPostRefreshSummary(ok: 1);
  }
}

FacebookPostRecord _record(String id) => FacebookPostRecord(
  id: id,
  postId: 'post_$id',
  snippet: 'Snippet $id',
  timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  hasImage: false,
  permalink: 'https://facebook.com/$id',
);

void main() {
  test(
    'a throwing record does not escape refreshStale or wedge running',
    () async {
      final history = _ThrowingHistory([_record('a'), _record('boom')]);
      final container = ProviderContainer(
        overrides: [facebookHistoryProvider.overrideWith(() => history)],
      );
      addTearDown(container.dispose);

      final refresher = container.read(
        facebookInsightsRefresherProvider.notifier,
      );

      final attempted = await refresher.refreshStale();
      expect(attempted, 2);
      expect(refresher.running, isFalse);

      // A second run must still work: the flag was not left stuck true.
      await refresher.refreshStale();
      expect(refresher.running, isFalse);
      expect(history.calls, greaterThan(2));
    },
  );

  test('no candidates leaves running false', () async {
    final history = _ThrowingHistory(const []);
    final container = ProviderContainer(
      overrides: [facebookHistoryProvider.overrideWith(() => history)],
    );
    addTearDown(container.dispose);

    final refresher = container.read(
      facebookInsightsRefresherProvider.notifier,
    );
    expect(await refresher.refreshStale(), 0);
    expect(refresher.running, isFalse);
  });
}
