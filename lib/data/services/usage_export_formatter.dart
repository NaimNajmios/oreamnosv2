import 'dart:convert';

import 'package:intl/intl.dart';

import '../../domain/models/usage_log.dart';

/// Pure formatters for the Usage history exports (CSV/JSON), mirroring the
/// shape of [FacebookExportFormatter] (RFC 4180-style CSV with BOM, JSON
/// envelope with filters + export metadata).
abstract final class UsageExportFormatter {
  /// Columns of the exported CSV: Time, Provider, Model, Tokens, Latency, Result.
  static const List<String> csvHeaders = [
    'Time',
    'Provider',
    'Model',
    'Tokens',
    'Latency',
    'Result',
  ];

  static String csv(Iterable<UsageLog> logs) {
    final buf = StringBuffer();
    buf.writeln(csvHeaders.map((h) => _csvEscape(h)).join(','));
    for (final log in logs) {
      final fields = <String>[
        _timestamp(log),
        _csvEscape(log.providerId),
        _csvEscape(log.modelName ?? ''),
        log.estimatedTokens.toString(),
        '${log.latencyMs}ms',
        _csvEscape(log.isSuccess ? 'Success' : 'Failed'),
      ];
      buf.writeln(fields.join(','));
    }
    return buf.toString();
  }

  static String json(
    Iterable<UsageLog> logs, {
    String? rangeLabel,
    String? providerFilter,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'range': rangeLabel,
      'providerFilter': providerFilter,
      'exportedAt': DateTime.now().toIso8601String(),
      'count': logs.length,
      'logs': [for (final log in logs) log.toJson()],
    });
  }

  static String _timestamp(UsageLog log) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp);

  /// RFC 4180: wrap in quotes when the field contains a comma, quote, or
  /// line break, and double internal quotes.
  static String _csvEscape(String value) {
    if (value.isEmpty) return '';
    if (!value.contains(',') && !value.contains('"') && !value.contains('\n')) {
      return value;
    }
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return '"${normalized.replaceAll('"', '""')}"';
  }
}
