import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/share_intent_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  group('ShareIntentService', () {
    late ShareIntentService service;

    setUp(() {
      service = ShareIntentService();
      service.resetDeduplicationForTesting();
      service.onSharedTextReceived = null;
    });

    tearDown(() {
      service.resetDeduplicationForTesting();
      service.onSharedTextReceived = null;
    });

    test('invokes onSharedTextReceived for valid text media', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      service.handleSharedMedia([
        SharedMediaFile(
          path: 'https://twitter.com/fabrizioromano/status/123456789',
          type: SharedMediaType.text,
        ),
      ]);

      expect(received, ['https://twitter.com/fabrizioromano/status/123456789']);
    });

    test('invokes onSharedTextReceived for valid url media', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      service.handleSharedMedia([
        SharedMediaFile(
          path: 'https://theathletic.com/article/123',
          type: SharedMediaType.url,
        ),
      ]);

      expect(received, ['https://theathletic.com/article/123']);
    });

    test('ignores non-text/url media types', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      service.handleSharedMedia([
        SharedMediaFile(
          path: '/path/to/image.jpg',
          type: SharedMediaType.image,
        ),
      ]);

      expect(received, isEmpty);
    });

    test('ignores empty files list and blank content', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      service.handleSharedMedia([]);
      service.handleSharedMedia([
        SharedMediaFile(path: '   ', type: SharedMediaType.text),
      ]);

      expect(received, isEmpty);
    });

    test('deduplicates identical shared content received within 1500ms', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      const content = 'https://x.com/sports/status/987654321';

      service.handleSharedMedia([
        SharedMediaFile(path: content, type: SharedMediaType.text),
      ]);
      // Immediate duplicate delivery (e.g., warm app resume stream bounce)
      service.handleSharedMedia([
        SharedMediaFile(path: content, type: SharedMediaType.text),
      ]);

      expect(received.length, 1);
      expect(received.first, content);
    });

    test('processes distinct shared content sequentially', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      service.handleSharedMedia([
        SharedMediaFile(
          path: 'https://x.com/sports/status/1',
          type: SharedMediaType.text,
        ),
      ]);
      service.handleSharedMedia([
        SharedMediaFile(
          path: 'https://x.com/sports/status/2',
          type: SharedMediaType.text,
        ),
      ]);

      expect(received, [
        'https://x.com/sports/status/1',
        'https://x.com/sports/status/2',
      ]);
    });

    test('allows re-processing after deduplication cache is reset', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      const content = 'https://x.com/sports/status/100';

      service.handleSharedMedia([
        SharedMediaFile(path: content, type: SharedMediaType.text),
      ]);
      expect(received.length, 1);

      service.resetDeduplicationForTesting();

      service.handleSharedMedia([
        SharedMediaFile(path: content, type: SharedMediaType.text),
      ]);
      expect(received.length, 2);
    });

    test('normalizeDedupKey strips tracking params and casing', () {
      const a = 'https://x.com/oreamnos/status/123456?s=20&t=abcDEF';
      const b = 'HTTPS://X.COM/oreamnos/status/123456/';
      const c = 'https://x.com/oreamnos/status/999999';

      expect(
        ShareIntentService.normalizeDedupKey(a),
        contains('status/123456'),
      );
      expect(ShareIntentService.normalizeDedupKey(a), isNot(contains('?')));
      expect(
        ShareIntentService.normalizeDedupKey(a),
        equalsIgnoringCase(ShareIntentService.normalizeDedupKey(b)),
      );
      expect(
        ShareIntentService.normalizeDedupKey(a),
        isNot(equals(ShareIntentService.normalizeDedupKey(c))),
      );
    });

    test('normalizes differently-tracked versions of the same tweet as '
        'duplicates', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      const tracked = 'https://x.com/sports/status/987654321?s=20&t=xyz';
      const plain = 'https://x.com/sports/status/987654321';

      service.handleSharedMedia([
        SharedMediaFile(path: tracked, type: SharedMediaType.text),
      ]);
      service.handleSharedMedia([
        SharedMediaFile(path: plain, type: SharedMediaType.text),
      ]);

      // Same logical share re-shared with different tracking params within
      // the dedup window: one delivery (and the *last* content wins).
      expect(received.length, 1);
    });

    test('whitespace-only differences in plain text dedupe within window', () {
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      service.handleSharedMedia([
        SharedMediaFile(
          path: 'Breaking: Oreamnos reaches v2',
          type: SharedMediaType.text,
        ),
      ]);
      service.handleSharedMedia([
        SharedMediaFile(
          path: 'Breaking:  Oreamnos   reaches v2',
          type: SharedMediaType.text,
        ),
      ]);

      expect(received.length, 1);
    });
  });
}
