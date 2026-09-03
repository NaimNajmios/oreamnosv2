import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/services/source_policy.dart';

void main() {
  group('SourcePolicy', () {
    test('rejects URL/domain/platform/handle labels', () {
      for (final bad in [
        'https://bbc.com/sport',
        'http://example.com',
        'www.bbc.com',
        'bbc.com',
        'x.com',
        'twitter.com',
        'X',
        'Twitter',
        't.co',
        '@FabrizioRomano',
        'FabrizioRomano',
      ]) {
        expect(
          SourcePolicy.sanitizeLabel(bad),
          '',
          reason: 'should reject "$bad"',
        );
      }
    });

    test('keeps valid outlet labels', () {
      expect(SourcePolicy.sanitizeLabel('BBC Sport'), 'BBC Sport');
      expect(
        SourcePolicy.sanitizeLabel('BBC Sport via Fabrizio Romano'),
        'BBC Sport via Fabrizio Romano',
      );
    });

    test('strips trailing via-platform suffix', () {
      expect(SourcePolicy.sanitizeLabel('BBC Sport via X'), 'BBC Sport');
      expect(
        SourcePolicy.sanitizeLabel('BBC Sport via twitter.com'),
        'BBC Sport',
      );
    });

    test('repairs Outlet via @handle with display name', () {
      expect(
        SourcePolicy.sanitizeLabel(
          'BBC Sport via @FabrizioRomano',
          authorDisplayName: 'Fabrizio Romano',
        ),
        'BBC Sport via Fabrizio Romano',
      );
      // Without display name, drop the handle and keep outlet only.
      expect(
        SourcePolicy.sanitizeLabel('BBC Sport via @FabrizioRomano'),
        'BBC Sport',
      );
    });

    test('extractOutletFromTweet finds named outlet, never URL/handle', () {
      expect(
        SourcePolicy.extractOutletFromTweet(
          'According to BBC Sport, Arsenal win 2-0.',
        ),
        isNotNull,
      );
      expect(
        SourcePolicy.extractOutletFromTweet('Just my opinion on the game!'),
        isNull,
      );
      expect(
        SourcePolicy.extractOutletFromTweet('Check https://bbc.com/sport'),
        isNull,
      );
    });
  });

  group('CuratedPost source hardening', () {
    test('URL-derived label is blanked but url preserved', () {
      final post = CuratedPost.fromJson({
        'title': 'T',
        'body': 'B',
        'source': {'label': 'bbc.com', 'url': 'https://bbc.com/sport'},
      });
      expect(post.source.label, '');
      expect(post.source.url, 'https://bbc.com/sport');
    });

    test('platform/handle labels are blanked', () {
      for (final bad in ['X', 'twitter.com', '@FabrizioRomano']) {
        final post = CuratedPost.fromJson({
          'title': 'T',
          'body': 'B',
          'source': {'label': bad, 'url': ''},
        });
        expect(post.source.label, '', reason: 'should blank "$bad"');
      }
    });

    test('toMarkdownFiltered never emits URL as Sumber', () {
      final post = CuratedPost.fromJson({
        'title': 'T',
        'body': 'B',
        'source': {'label': '', 'url': 'https://bbc.com/sport'},
      });
      final md = post.toMarkdownFiltered(
        showTitle: false,
        showHashtags: false,
        showSource: true,
        appendSourceForCopy: true,
      );
      expect(md, isNot(contains('Sumber')));
      expect(md, isNot(contains('bbc.com')));
    });

    test('valid outlet label is copied as Sumber', () {
      final post = CuratedPost.fromJson({
        'title': 'T',
        'body': 'B',
        'source': {
          'label': 'BBC Sport via Fabrizio Romano',
          'url': 'https://x.com/foo/status/1',
        },
      });
      final md = post.toMarkdownFiltered(
        showTitle: false,
        showHashtags: false,
        showSource: true,
        appendSourceForCopy: true,
      );
      expect(md, contains('Sumber: BBC Sport via Fabrizio Romano'));
    });
  });
}
