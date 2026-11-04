import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/data/services/facebook_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('oreamnos_docs');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return docs.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (docs.existsSync()) await docs.delete(recursive: true);
  });

  Future<FacebookDraftStore> makeStore() async {
    final prefs = await SharedPreferences.getInstance();
    return FacebookDraftStore(prefs);
  }

  FacebookDraftRecord record(
    String id, {
    String text = 'Draft',
    List<Map<String, dynamic>> media = const [],
    DateTime? at,
  }) {
    return FacebookDraftRecord(
      id: id,
      text: text,
      media: media,
      pageId: '123',
      pageName: 'Trace',
      mode: 'now',
      updatedAt: at ?? DateTime.now(),
    );
  }

  test('save, newest-first ordering and cap at 20', () async {
    final store = await makeStore();
    final base = DateTime(2026, 1, 1);
    for (var i = 0; i < 21; i++) {
      await store.save(
        record(
          'd$i',
          text: 'Draft $i',
          at: base.add(Duration(minutes: i)),
        ),
      );
    }
    final all = store.loadAll();
    expect(all, hasLength(FacebookDraftStore.maxDrafts));
    expect(all.first.id, 'd20');
    expect(all.last.id, 'd1');
  });

  test('active draft points at the most recent save', () async {
    final store = await makeStore();
    await store.save(record('a'));
    await store.save(record('b'));
    expect(store.activeDraftId, 'b');
    expect(store.loadActive()?.id, 'b');
    await store.setActive('a');
    expect(store.loadActive()?.id, 'a');
  });

  test('delete removes the record and its images', () async {
    final store = await makeStore();
    final source = File('${docs.path}/source.png');
    await source.writeAsBytes([1, 2, 3]);
    final media = await store.importMedia('gone', [
      {'path': source.path},
    ]);
    await store.save(record('gone', media: media));
    final copied = File(media.single['path'] as String);
    expect(copied.existsSync(), isTrue);

    await store.delete('gone');
    expect(store.loadAll(), isEmpty);
    expect(copied.existsSync(), isFalse);
    expect(store.activeDraftId, isNull);
  });

  test(
    'images are copied into app documents and survive source deletion',
    () async {
      final store = await makeStore();
      final source = File('${docs.path}/temp.png');
      await source.writeAsBytes([9, 8, 7]);
      final media = await store.importMedia('keep', [
        {'path': source.path, 'altText': 'Pitch'},
      ]);
      await store.save(record('keep', media: media));
      await source.delete();

      final loaded = store.loadAll().single;
      final copied = File(loaded.media.single['path'] as String);
      expect(copied.existsSync(), isTrue);
      expect(loaded.media.single['altText'], 'Pitch');
    },
  );

  test('duplicate copies text and media under a new id', () async {
    final store = await makeStore();
    final source = File('${docs.path}/temp.png');
    await source.writeAsBytes([4, 5]);
    await store.save(
      record(
        'original',
        text: 'Copy me',
        media: await store.importMedia('original', [
          {'path': source.path},
        ]),
      ),
    );
    final newId = await store.duplicate('original');
    expect(newId, isNotNull);
    final copy = store.loadAll().firstWhere((r) => r.id == newId);
    expect(copy.text, 'Copy me');
    expect(copy.media.single['path'], isNot(contains('original')));
    expect(File(copy.media.single['path'] as String).existsSync(), isTrue);
  });

  test('v10 single draft key migrates into the store', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyFacebookDraft,
      jsonEncode({'text': 'Legacy draft', 'imagePath': '', 'aspect': 'square'}),
    );
    final store = FacebookDraftStore(prefs);
    final id = await store.migrateLegacyDraft();
    expect(id, isNotNull);
    final record = store.loadAll().single;
    expect(record.text, 'Legacy draft');
    expect(prefs.getString(AppConstants.keyFacebookDraft), isNull);
    expect(store.activeDraftId, record.id);
  });
}
