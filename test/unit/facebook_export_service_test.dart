import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_export_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';

FacebookPostRecord _record() => FacebookPostRecord(
  id: 'r1',
  postId: 'post_1',
  snippet: 'Matchday',
  message: 'Caption',
  timestamp: DateTime(2026, 11, 10, 20),
  hasImage: false,
  permalink: 'https://facebook.com/post_1',
  status: FacebookPostStatus.published,
  pageId: 'page-1',
  pageName: 'JDT',
);

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('oreamnos_export');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('writes a timestamped CSV with a UTF-8 BOM', () async {
    final service = FacebookExportService(tempDirectory: () async => dir);
    final file = await service.write(
      format: FacebookExportFormat.csv,
      records: [_record()],
    );

    expect(file.path, endsWith('.csv'));
    expect(file.path, contains('oreamnos_facebook_history_'));
    final bytes = await file.readAsBytes();
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = String.fromCharCodes(bytes.skip(3));
    expect(text, contains('id,status,story_status'));
    expect(text, contains('post_1'));
  });

  test('writes JSON without a BOM', () async {
    final service = FacebookExportService(tempDirectory: () async => dir);
    final file = await service.write(
      format: FacebookExportFormat.json,
      records: [_record()],
    );

    expect(file.path, endsWith('.json'));
    final text = await file.readAsString();
    expect(text.trimLeft(), startsWith('{'));
    expect(text, isNot(contains('access_token')));
  });
}
