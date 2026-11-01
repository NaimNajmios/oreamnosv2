import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/share_intent_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('fresh cold-start initial share is handled and persists its '
        'fingerprint', () async {
      SharedPreferences.setMockInitialValues({});
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      const content = 'https://x.com/sports/status/5554443332';
      await service.loadInitialFingerprintForTesting();
      expect(service.initialFingerprintForTesting, isNull);

      service.handleSharedMedia([
        SharedMediaFile(path: content, type: SharedMediaType.text),
      ], isInitial: true);

      expect(received, [content]);
      expect(
        service.initialFingerprintForTesting,
        ShareIntentService.normalizeDedupKey(content),
      );

      // The fingerprint must reach prefs so a *new* process can recognize
      // a stale replay of the same content on its initial path.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('share_initial_fingerprint'),
        service.initialFingerprintForTesting,
      );
    });

    test('stale initial replay after process restart is suppressed, but a '
        'distinct share passes', () async {
      SharedPreferences.setMockInitialValues({});
      final received = <String>[];
      service.onSharedTextReceived = (text) => received.add(text);

      const handled = 'https://x.com/sports/status/1112223334445556666';
      const fresh = 'https://x.com/sports/status/999888777666555';

      // Session 1: initial cold-start share handled.
      await service.loadInitialFingerprintForTesting();
      service.handleSharedMedia([
        SharedMediaFile(path: handled, type: SharedMediaType.text),
      ], isInitial: true);
      expect(received, [handled]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Session 2 (new "process"): in-memory state gone, fingerprint
      // reloaded from prefs — Android's cached process replays the SAME
      // initial share, which must be suppressed...
      service.resetDeduplicationForTesting();
      await service.loadInitialFingerprintForTesting();
      expect(
        service.initialFingerprintForTesting,
        ShareIntentService.normalizeDedupKey(handled),
      );

      service.handleSharedMedia([
        SharedMediaFile(path: handled, type: SharedMediaType.text),
      ], isInitial: true);
      expect(received, [handled]);

      // ...but a genuinely NEW share on the initial path is handled.
      service.handleSharedMedia([
        SharedMediaFile(path: fresh, type: SharedMediaType.text),
      ], isInitial: true);
      expect(received, [handled, fresh]);
    });

    test(
      'transient (stream) deliveries never update the initial fingerprint',
      () async {
        SharedPreferences.setMockInitialValues({});
        final received = <String>[];
        service.onSharedTextReceived = (text) => received.add(text);

        await service.loadInitialFingerprintForTesting();
        service.handleSharedMedia([
          SharedMediaFile(
            path: 'https://x.com/sports/status/777777',
            type: SharedMediaType.text,
          ),
          // default isInitial: false — live-stream path
        ]);

        expect(received, hasLength(1));
        expect(service.initialFingerprintForTesting, isNull);
      },
    );
  });
}
