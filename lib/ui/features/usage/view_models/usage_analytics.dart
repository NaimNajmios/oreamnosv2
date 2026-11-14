import 'package:oreamnos/domain/models/usage_log.dart';

/// Single derived view of the Usage log list.
///
/// The range cutoff is applied once, then the provider filter, so every stat
/// card and chart on the Usage tab reads the exact same records.
class UsageAnalytics {
  const UsageAnalytics({
    required this.logs,
    required this.totalTokens,
    required this.successCount,
    required this.successRate,
    required this.avgLatency,
    required this.rangeDays,
    required this.providerFilter,
  });

  final List<UsageLog> logs;
  final int totalTokens;
  final int successCount;
  final double successRate;
  final int avgLatency;
  final int rangeDays;
  final String providerFilter;

  bool get hasData => logs.isNotEmpty;

  bool get isAllTime => rangeDays <= 0;

  String get rangeLabel => isAllTime ? 'all time' : 'the last $rangeDays days';

  List<UsageLog> get successes =>
      logs.where((log) => log.isSuccess).toList(growable: false);

  factory UsageAnalytics.from(
    List<UsageLog> all, {
    required int rangeDays,
    required String providerFilter,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final cutoff = rangeDays > 0
        ? reference.subtract(Duration(days: rangeDays))
        : null;
    final filter = providerFilter.trim().toLowerCase();
    final logs = all
        .where((log) {
          if (cutoff != null && !log.timestamp.isAfter(cutoff)) return false;
          if (filter.isNotEmpty && filter != 'all') {
            return log.providerId.toLowerCase() == filter;
          }
          return true;
        })
        .toList(growable: false);

    var totalTokens = 0;
    var successCount = 0;
    var totalLatency = 0;
    for (final log in logs) {
      totalTokens += log.estimatedTokens;
      totalLatency += log.latencyMs;
      if (log.isSuccess) successCount++;
    }

    return UsageAnalytics(
      logs: logs,
      totalTokens: totalTokens,
      successCount: successCount,
      successRate: logs.isEmpty ? 0.0 : successCount / logs.length * 100,
      avgLatency: logs.isEmpty ? 0 : totalLatency ~/ logs.length,
      rangeDays: rangeDays,
      providerFilter: filter.isEmpty ? 'all' : filter,
    );
  }
}
