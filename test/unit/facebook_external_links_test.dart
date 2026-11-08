import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/features/facebook/utils/facebook_external_links.dart';

FacebookPostRecord _record({
  String permalink = 'https://www.facebook.com/123/posts/456',
  FacebookStoryStatus storyStatus = FacebookStoryStatus.published,
  bool isStoryOnly = false,
}) {
  return FacebookPostRecord(
    id: 'id',
    postId: '456',
    snippet: 'snippet',
    timestamp: DateTime(2026, 11, 8),
    hasImage: true,
    permalink: permalink,
    storyStatus: storyStatus,
    isStoryOnly: isStoryOnly,
  );
}

void main() {
  group('facebookPostUri', () {
    test('accepts a valid https permalink', () {
      final uri = facebookPostUri('https://www.facebook.com/123/posts/456');
      expect(uri, isNotNull);
      expect(uri!.host, 'www.facebook.com');
    });

    test('accepts http as well', () {
      expect(facebookPostUri('http://example.com/post'), isNotNull);
    });

    test('rejects empty and whitespace-only values', () {
      expect(facebookPostUri(''), isNull);
      expect(facebookPostUri('   '), isNull);
    });

    test('rejects non-web schemes', () {
      expect(facebookPostUri('javascript:alert(1)'), isNull);
      expect(facebookPostUri('data:text/plain,hello'), isNull);
      expect(facebookPostUri('file:///tmp/post'), isNull);
    });

    test('rejects malformed values without a host', () {
      expect(facebookPostUri('https://'), isNull);
      expect(facebookPostUri('facebook.com/123'), isNull);
    });
  });

  group('feedPostUri', () {
    test('resolves a published feed post', () {
      final uri = feedPostUri(_record());
      expect(uri, isNotNull);
      expect(uri!.path, '/123/posts/456');
    });

    test('returns null for Story-only records', () {
      expect(feedPostUri(_record(permalink: '', isStoryOnly: true)), isNull);
    });

    test('returns null for a scheduled record without a permalink', () {
      expect(feedPostUri(_record(permalink: '')), isNull);
    });

    test('returns null for a malformed permalink', () {
      expect(feedPostUri(_record(permalink: 'not a url')), isNull);
    });
  });
}
