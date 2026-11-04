import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_draft_store.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late Directory temp;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('oreamnos_docs');
    temp = await Directory.systemTemp.createTemp('oreamnos_temp');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
              return docs.path;
            case 'getTemporaryDirectory':
              return temp.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (docs.existsSync()) await docs.delete(recursive: true);
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  Future<FacebookHistoryService> history() async =>
      FacebookHistoryService(await SharedPreferences.getInstance());

  Future<FacebookDraftStore> drafts() async =>
      FacebookDraftStore(await SharedPreferences.getInstance());

  test('history eviction deletes the oldest thumbnail', () async {
    final service = await history();
    final source = File('${temp.path}/source.png')..writeAsBytesSync([1, 2, 3]);
    final first = await service.recordPublish(
      postId: 'p0',
      message: 'First',
      permalink: '',
      hasImage: true,
      sourceImagePaths: [source.path],
    );
    final thumb = first.localImagePaths.single;
    expect(File(thumb).existsSync(), isTrue);

    for (var i = 1; i <= 50; i++) {
      await service.recordPublish(
        postId: 'p$i',
        message: 'Post $i',
        permalink: '',
        hasImage: true,
        sourceImagePaths: [source.path],
      );
    }
    expect(service.records, hasLength(50));
    expect(File(thumb).existsSync(), isFalse);
    expect(service.records.any((r) => r.postId == 'p0'), isFalse);
  });

  test('draft prune deletes only unreferenced files', () async {
    final store = await drafts();
    final dir = Directory('${docs.path}/facebook_drafts/d1')
      ..createSync(recursive: true);
    final keep = File('${dir.path}/keep.png')..writeAsBytesSync([1, 2]);
    final orphan = File('${dir.path}/orphan.png')..writeAsBytesSync([3, 4]);
    await store.save(
      FacebookDraftRecord(
        id: 'd1',
        text: 'Draft',
        media: [
          {'path': keep.path},
        ],
        pageId: 'p',
        pageName: 'Page',
        mode: 'now',
        updatedAt: DateTime.now(),
      ),
    );
    // save() itself prunes, so re-create the orphan to test explicitly.
    orphan.writeAsBytesSync([3, 4]);
    expect(orphan.existsSync(), isTrue);

    final freed = await store.pruneDraftMedia('d1');
    expect(freed, greaterThan(0));
    expect(keep.existsSync(), isTrue);
    expect(orphan.existsSync(), isFalse);
  });

  test('storage report and sweep remove orphans but keep live files', () async {
    final store = await drafts();
    final historyService = await history();
    final storage = FacebookStorageService(historyService, store);

    // Live history thumbnail + orphan.
    final thumbSource = File('${temp.path}/thumb-src.png')
      ..writeAsBytesSync([1]);
    final record = await historyService.recordPublish(
      postId: 'p1',
      message: 'Post',
      permalink: '',
      hasImage: true,
      sourceImagePaths: [thumbSource.path],
    );
    final liveThumb = record.localImagePaths.single;
    final thumbs = Directory('${docs.path}/facebook_thumbs');
    final orphanThumb = File('${thumbs.path}/orphan.png')
      ..writeAsBytesSync([8, 8, 8]);

    // Live draft file + orphan.
    final dir = Directory('${docs.path}/facebook_drafts/d1')
      ..createSync(recursive: true);
    final liveDraft = File('${dir.path}/live.png')..writeAsBytesSync([1, 1]);
    await store.save(
      FacebookDraftRecord(
        id: 'd1',
        text: 'Draft',
        media: [
          {'path': liveDraft.path},
        ],
        pageId: 'p',
        pageName: 'Page',
        mode: 'now',
        updatedAt: DateTime.now(),
      ),
    );
    final orphanDraft = File('${dir.path}/orphan.png')
      ..writeAsBytesSync([2, 2]);

    // Old temp crop + fresh temp crop.
    final oldTemp = File('${temp.path}/oreamnos_fb_old.jpg')
      ..writeAsBytesSync([5, 5]);
    oldTemp.setLastModifiedSync(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    final newTemp = File('${temp.path}/oreamnos_fb_new.jpg')
      ..writeAsBytesSync([6]);

    final report = await storage.report();
    expect(report.historyThumbnailBytes, greaterThan(0));
    expect(report.draftImageBytes, greaterThan(0));
    expect(report.tempUploadBytes, greaterThan(0));

    final freed = await storage.sweep();
    expect(freed, greaterThan(0));
    expect(File(liveThumb).existsSync(), isTrue);
    expect(orphanThumb.existsSync(), isFalse);
    expect(liveDraft.existsSync(), isTrue);
    expect(orphanDraft.existsSync(), isFalse);
    expect(oldTemp.existsSync(), isFalse);
    expect(newTemp.existsSync(), isTrue);
  });

  test('storage sweep is idempotent', () async {
    final storage = FacebookStorageService(await history(), await drafts());
    await storage.sweep();
    final second = await storage.sweep();
    expect(second, 0);
  });
}
