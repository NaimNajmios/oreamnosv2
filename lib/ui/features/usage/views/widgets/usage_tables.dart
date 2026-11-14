import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

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
