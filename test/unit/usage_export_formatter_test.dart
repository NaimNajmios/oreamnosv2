import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:oreamnos/data/services/usage_export_formatter.dart';
import 'package:oreamnos/domain/models/usage_log.dart';

UsageLog _log({
  String id = 'id',
  DateTime? timestamp,
  String providerId = 'gemini',
  String? modelName,
  int latencyMs = 100,
  int estimatedTokens = 200,
  bool isSuccess = true,
  String? requestId,
  String? error,
  int? promptTokens,
  int? completionTokens,
}) => UsageLog(
  id: id,
  timestamp: timestamp ?? DateTime(2026, 11, 20, 10, 30, 5),
  providerId: providerId,
  modelName: modelName,
  latencyMs: latencyMs,
  estimatedTokens: estimatedTokens,
  isSuccess: isSuccess,
  requestId: requestId,
  error: error,
  promptTokens: promptTokens,
  completionTokens: completionTokens,
);

void main() {
  group('UsageExportFormatter.csv', () {
    test('emits the expected header', () {
      expect(
        UsageExportFormatter.csv([]),
        startsWith('Time,Provider,Model,Tokens,Latency,Result\n'),
      );
    });

    test('writes one row per log with formatted values', () {
      final out = UsageExportFormatter.csv([_log()]);
      final lines = out.trim().split('\n');
      expect(lines.length, 2);
      expect(
        lines.last.startsWith(
          DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(DateTime(2026, 11, 20, 10, 30, 5)),
        ),
        isTrue,
      );
      expect(lines.last, contains(',gemini,,200,100ms,Success'));
    });

    test('escapes commas, quotes and newlines per RFC 4180', () {
      final out = UsageExportFormatter.csv([
        _log(providerId: 'g,q', modelName: 'a,b"c', isSuccess: false),
      ]);
      expect(out, contains('"g,q"'));
      expect(out, contains('"a,b""c"'));
      expect(out, contains('Failed'));
    });
  });

  group('UsageExportFormatter.json', () {
    test('envelope carries filters, exportedAt and the logs', () {
      final log = _log(requestId: 'r1', promptTokens: 10, completionTokens: 20);
      final decoded = jsonDecode(
        UsageExportFormatter.json(
          [log],
          rangeLabel: 'the last 7 days',
          providerFilter: 'gemini',
        ),
      ) as Map<String, dynamic>;
      expect(decoded['range'], 'the last 7 days');
      expect(decoded['providerFilter'], 'gemini');
      expect(decoded['count'], 1);
      expect((decoded['exportedAt'] as String).isNotEmpty, isTrue);
      final entry = (decoded['logs'] as List).single as Map<String, dynamic>;
      expect(entry['estimatedTokens'], 200);
      expect(entry['requestId'], 'r1');
      expect(entry['promptTokens'], 10);
      expect(entry['completionTokens'], 20);
    });
  });

  group('UsageLog round-trip', () {
    test('new fields survive toJson/fromJson', () {
      final log = _log(
        requestId: 'r9',
        error: 'Rate limited — retry in 30s',
        promptTokens: 10,
        completionTokens: 20,
      );
      final decoded = UsageLog.fromJson(log.toJson());
      expect(decoded.requestId, 'r9');
      expect(decoded.error, 'Rate limited — retry in 30s');
      expect(decoded.promptTokens, 10);
      expect(decoded.completionTokens, 20);
    });
  });
}
