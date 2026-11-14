import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/domain/models/usage_log.dart';
import 'package:oreamnos/ui/features/usage/view_models/usage_analytics.dart';

UsageLog log({
  required String id,
  required String providerId,
  required DateTime at,
  int tokens = 10,
  int latency = 100,
  bool success = true,
}) {
  return UsageLog(
    id: id,
    timestamp: at,
    providerId: providerId,
    latencyMs: latency,
    estimatedTokens: tokens,
    isSuccess: success,
  );
}

void main() {
  final now = DateTime(2026, 6, 15, 12);
  final logs = [
    log(
      id: '1',
      providerId: 'gemini',
      at: now.subtract(const Duration(hours: 1)),
      tokens: 100,
      latency: 200,
    ),
    log(
      id: '2',
      providerId: 'gemini',
      at: now.subtract(const Duration(days: 2)),
      tokens: 50,
      latency: 400,
      success: false,
    ),
    log(
      id: '3',
      providerId: 'groq',
      at: now.subtract(const Duration(days: 10)),
      tokens: 25,
      latency: 600,
    ),
    log(
      id: '4',
      providerId: 'groq',
      at: now.subtract(const Duration(days: 40)),
      tokens: 5,
      latency: 800,
    ),
  ];

  test('all time includes every log and totals match', () {
    final analytics = UsageAnalytics.from(
      logs,
      rangeDays: 0,
      providerFilter: 'all',
      now: now,
    );
    expect(analytics.logs, hasLength(4));
    expect(analytics.totalTokens, 180);
    expect(analytics.successCount, 3);
    expect(analytics.successRate, 75);
    expect(analytics.avgLatency, 500);
    expect(analytics.isAllTime, isTrue);
  });

  test('range cutoff is exclusive and applies before provider filter', () {
    final analytics = UsageAnalytics.from(
      logs,
      rangeDays: 7,
      providerFilter: 'gemini',
      now: now,
    );
    expect(analytics.logs.map((log) => log.id), ['1', '2']);
    expect(analytics.totalTokens, 150);
    expect(analytics.successCount, 1);
    expect(analytics.successRate, 50);
    expect(analytics.avgLatency, 300);
    expect(analytics.rangeLabel, 'the last 7 days');
  });

  test('provider filter with no matches yields an empty, zeroed view', () {
    final analytics = UsageAnalytics.from(
      logs,
      rangeDays: 30,
      providerFilter: 'cerebras',
      now: now,
    );
    expect(analytics.hasData, isFalse);
    expect(analytics.totalTokens, 0);
    expect(analytics.successRate, 0);
    expect(analytics.avgLatency, 0);
  });

  test('a log exactly on the cutoff is excluded', () {
    final analytics = UsageAnalytics.from(
      [
        log(
          id: 'edge',
          providerId: 'gemini',
          at: now.subtract(const Duration(days: 7)),
        ),
      ],
      rangeDays: 7,
      providerFilter: 'all',
      now: now,
    );
    expect(analytics.hasData, isFalse);
  });
}
