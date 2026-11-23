import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

/// Per-model summary (requests, tokens, success rate, latency stats) shown
/// above the Usage tab's provider-level tables.
class ModelBreakdownTable extends StatelessWidget {
  const ModelBreakdownTable({super.key, required this.logs});

  final List<UsageLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <String, List<UsageLog>>{};
    final display = <String, String>{};
    for (final log in logs) {
      final key =
          '${log.providerId.toLowerCase()}:${log.modelName?.trim() ?? ''}';
      grouped.putIfAbsent(key, () => []).add(log);
      display[key] ??= log.providerModelText;
    }

    final rows =
        grouped.entries
            .map(
              (e) => (
                label: display[e.key]!,
                logs: e.value,
                count: e.value.length,
                tokens: e.value.fold<int>(0, (s, l) => s + l.estimatedTokens),
                rate: _rateAll(e.value),
                avg: _avgAll(e.value),
                median: _medianLatencies(e.value),
                p95: _p95Latencies(e.value),
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BY MODEL',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _TableFrame(
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 56,
            columnSpacing: AppSpacing.base,
            columns: const [
              DataColumn(label: Text('Model')),
              DataColumn(label: Text('Requests'), numeric: true),
              DataColumn(label: Text('Tokens'), numeric: true),
              DataColumn(label: Text('Rate'), numeric: true),
              DataColumn(label: Text('Avg'), numeric: true),
              DataColumn(label: Text('Median'), numeric: true),
              DataColumn(label: Text('P95'), numeric: true),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    DataCell(Text(row.label)),
                    DataCell(Text('${row.count}')),
                    DataCell(Text('${row.tokens}')),
                    DataCell(Text('${row.rate}%')),
                    DataCell(Text('${row.avg}ms')),
                    DataCell(Text(_fmt(_medianLatencies(row.logs)))),
                    DataCell(Text(_fmt(_p95Latencies(row.logs)))),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

int _rateAll(List<UsageLog> logs) {
  if (logs.isEmpty) return 0;
  final successes = logs.where((l) => l.isSuccess).length;
  return (successes / logs.length * 100).round();
}

int _avgAll(List<UsageLog> logs) {
  if (logs.isEmpty) return 0;
  return logs.fold<int>(0, (s, l) => s + l.latencyMs) ~/ logs.length;
}

/// Tabular fallbacks for the Usage charts. Every table is horizontally
/// scrollable so 200% text scaling never clips a column.
class UsageTable extends StatelessWidget {
  const UsageTable({super.key, required this.logs});

  final List<UsageLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = logs.take(50).toList(growable: false);
    return _TableFrame(
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 56,
        columnSpacing: AppSpacing.base,
        columns: const [
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Provider')),
          DataColumn(label: Text('Tokens'), numeric: true),
          DataColumn(label: Text('Latency'), numeric: true),
          DataColumn(label: Text('Result')),
        ],
        rows: [
          for (final log in rows)
            DataRow(
              cells: [
                DataCell(
                  Text(DateFormat('MMM d, HH:mm').format(log.timestamp)),
                ),
                DataCell(Text(log.providerModelText)),
                DataCell(Text('${log.estimatedTokens}')),
                DataCell(Text('${log.latencyMs}ms')),
                DataCell(
                  Text(
                    log.isSuccess ? 'Success' : 'Failed',
                    style: TextStyle(
                      color: log.isSuccess
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class SuccessRateTable extends StatelessWidget {
  const SuccessRateTable({super.key, required this.logs});

  final List<UsageLog> logs;

  @override
  Widget build(BuildContext context) {
    final providers = _providers(logs);
    return _TableFrame(
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 56,
        columnSpacing: AppSpacing.base,
        columns: const [
          DataColumn(label: Text('Provider')),
          DataColumn(label: Text('Success'), numeric: true),
          DataColumn(label: Text('Rate'), numeric: true),
        ],
        rows: [
          for (final provider in providers)
            DataRow(
              cells: [
                DataCell(Text(_label(provider))),
                DataCell(
                  Text(
                    '${_successes(logs, provider)} / '
                    '${_count(logs, provider)}',
                  ),
                ),
                DataCell(Text('${_rate(logs, provider)}%')),
              ],
            ),
        ],
      ),
    );
  }
}

class ResponseTimeTable extends StatelessWidget {
  const ResponseTimeTable({super.key, required this.logs});

  final List<UsageLog> logs;

  @override
  Widget build(BuildContext context) {
    final providers = _providers(logs);
    return _TableFrame(
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 56,
        columnSpacing: AppSpacing.base,
        columns: const [
          DataColumn(label: Text('Provider')),
          DataColumn(label: Text('Avg'), numeric: true),
          DataColumn(label: Text('Median'), numeric: true),
          DataColumn(label: Text('P95'), numeric: true),
          DataColumn(label: Text('Min'), numeric: true),
          DataColumn(label: Text('Max'), numeric: true),
          DataColumn(label: Text('Count'), numeric: true),
        ],
        rows: [
          for (final provider in providers)
            DataRow(
              cells: [
                DataCell(Text(_label(provider))),
                DataCell(Text('${_avg(logs, provider)}ms')),
                DataCell(Text(_fmt(_medianLatencies(logs, provider)))),
                DataCell(Text(_fmt(_p95Latencies(logs, provider)))),
                DataCell(Text('${_min(logs, provider)}ms')),
                DataCell(Text('${_max(logs, provider)}ms')),
                DataCell(Text('${_count(logs, provider)}')),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableFrame extends StatelessWidget {
  const _TableFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    );
  }
}

List<String> _providers(List<UsageLog> logs) {
  final providers = <String>[];
  for (final log in logs) {
    final id = log.providerId.toLowerCase();
    if (!providers.contains(id)) providers.add(id);
  }
  return providers;
}

String _label(String provider) => provider.isEmpty
    ? provider
    : provider[0].toUpperCase() + provider.substring(1);

int _count(List<UsageLog> logs, String provider) =>
    logs.where((log) => log.providerId.toLowerCase() == provider).length;

int _successes(List<UsageLog> logs, String provider) => logs
    .where((log) => log.providerId.toLowerCase() == provider && log.isSuccess)
    .length;

int _rate(List<UsageLog> logs, String provider) {
  final total = _count(logs, provider);
  if (total == 0) return 0;
  return (_successes(logs, provider) / total * 100).round();
}

List<int> _latencies(List<UsageLog> logs, String provider) => logs
    .where((log) => log.providerId.toLowerCase() == provider)
    .map((log) => log.latencyMs)
    .toList(growable: false);

/// Latencies of [provider]'s logs (all logs when empty), sorted ascending.
List<int> _sortedLatencies(List<UsageLog> logs, [String provider = '']) =>
    logs
        .where(
          (log) => provider.isEmpty || log.providerId.toLowerCase() == provider,
        )
        .map((log) => log.latencyMs)
        .toList()
      ..sort();

/// Median of [latencies] (all logs when [provider] is empty), or null when
/// the list is empty.
int? _medianLatencies(List<UsageLog> logs, [String provider = '']) {
  final latencies = _sortedLatencies(logs, provider);
  if (latencies.isEmpty) return null;
  final mid = latencies.length ~/ 2;
  return latencies.length.isOdd
      ? latencies[mid]
      : ((latencies[mid - 1] + latencies[mid]) / 2).round();
}

/// Approximate 95th-percentile of [latencies], or null when empty.
int? _p95Latencies(List<UsageLog> logs, [String provider = '']) {
  final latencies = _sortedLatencies(logs, provider);
  if (latencies.isEmpty) return null;
  if (latencies.length == 1) return latencies.first;
  final rank = 0.95 * (latencies.length - 1);
  final lower = rank.floor();
  final upper = rank.ceil();
  if (lower == upper) return latencies[lower];
  final weight = rank - lower;
  return (latencies[lower] * (1 - weight) + latencies[upper] * weight).round();
}

String _fmt(int? value) => value == null ? '-' : '$value';

int _avg(List<UsageLog> logs, String provider) {
  final values = _latencies(logs, provider);
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) ~/ values.length;
}

int _min(List<UsageLog> logs, String provider) {
  final values = _latencies(logs, provider);
  return values.isEmpty ? 0 : values.reduce(math.min);
}

int _max(List<UsageLog> logs, String provider) {
  final values = _latencies(logs, provider);
  return values.isEmpty ? 0 : values.reduce(math.max);
}
