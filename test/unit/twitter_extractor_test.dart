import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/twitter_extractor.dart';

void main() {
  group('TwitterExtractor.extractArticleUrls', () {
    test('extracts standard article URLs', () {
      const text =
          'Breaking news about the match! Full report: https://theathletic.com/football/arsenal-chelsea';
      final urls = TwitterExtractor.extractArticleUrls(text);
      expect(urls, ['https://theathletic.com/football/arsenal-chelsea']);
    });

    test('extracts t.co shortlinks', () {
      const text = 'Official announcement here: https://t.co/xyz123abc';
      final urls = TwitterExtractor.extractArticleUrls(text);
      expect(urls, ['https://t.co/xyz123abc']);
    });

    test('strips trailing punctuation from URLs', () {
      const text =
          'Read the breakdown at https://bbc.com/sport/football/123. (Also check https://skysports.com/news!)';
      final urls = TwitterExtractor.extractArticleUrls(text);
      expect(urls, [
        'https://bbc.com/sport/football/123',
        'https://skysports.com/news',
      ]);
    });

    test('filters out internal twitter/x status URLs', () {
      const text =
          'Quote tweet: https://x.com/FabrizioRomano/status/123456789 and read more at https://fabrizioromano.com/post';
      final urls = TwitterExtractor.extractArticleUrls(text);
      expect(urls, ['https://fabrizioromano.com/post']);
    });

    test('returns empty list when no URLs exist', () {
      const text = 'Just a regular football tweet with no links or articles.';
      final urls = TwitterExtractor.extractArticleUrls(text);
      expect(urls, isEmpty);
    });
  });

  group('TwitterExtractor.formatForAiPrompt', () {
    test('formats without linked article content', () {
      final tweet = TweetContent(
        text: 'Arsenal lead 2-0 against Chelsea.',
        authorName: 'Arsenal FC',
        authorHandle: '@Arsenal',
        createdAt: '2026-09-04',
      );

      final prompt = TwitterExtractor.formatForAiPrompt(tweet);
      expect(prompt, contains('POST CONTENT:'));
      expect(prompt, contains('Arsenal lead 2-0 against Chelsea.'));
      expect(prompt, isNot(contains('LINKED ARTICLE CONTENT')));
    });

    test('formats with linked article content and URL', () {
      final tweet = TweetContent(
        text: 'Check out the tactical analysis https://t.co/link123',
        authorName: 'Tactics Journal',
        authorHandle: '@TacticsJournal',
        createdAt: '2026-09-04',
      );

      final prompt = TwitterExtractor.formatForAiPrompt(
        tweet,
        linkedArticleContent:
            'Arsenal dominated the midfield using a box structure.',
        linkedArticleUrl: 'https://theathletic.com/tactics/arsenal',
      );

      expect(prompt, contains('POST CONTENT:'));
      expect(
        prompt,
        contains('--- LINKED ARTICLE CONTENT (from link in post) ---'),
      );
      expect(
        prompt,
        contains('ARTICLE_URL: https://theathletic.com/tactics/arsenal'),
      );
      expect(
        prompt,
        contains('Arsenal dominated the midfield using a box structure.'),
      );
    });
  });
}
