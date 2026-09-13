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

    test('extracts from cardUrl and expandedUrls', () {
      final urls = TwitterExtractor.extractArticleUrls(
        'Check out this story',
        cardUrl: 'https://theathletic.com/story/1',
        expandedUrls: ['https://theathletic.com/story/2', 'https://t.co/abc'],
      );
      expect(urls, contains('https://theathletic.com/story/1'));
      expect(urls, contains('https://theathletic.com/story/2'));
      expect(urls, contains('https://t.co/abc'));
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

    test('formats with attached card preview and X article', () {
      final tweet = TweetContent(
        text: 'Huge breaking story published.',
        authorName: 'David Ornstein',
        authorHandle: '@David_Ornstein',
        createdAt: '2026-09-04',
        cardTitle: 'Arsenal agree deal in principle',
        cardDomain: 'theathletic.com',
        cardUrl: 'https://theathletic.com/transfer/exclusive',
        cardDescription: 'Full breakdown of the agreement reached today.',
        articleTitle: 'Inside the Negotiation',
        articleContent:
            'Arsenal executives finalized terms over a 48-hour period.',
        quoteText: 'Original quote text from previous discussion',
        quoteAuthor: 'Fabrizio Romano',
      );

      final prompt = TwitterExtractor.formatForAiPrompt(tweet);
      expect(
        prompt,
        contains('--- ATTACHED CARD / LINK PREVIEW (from post) ---'),
      );
      expect(prompt, contains('CARD TITLE: Arsenal agree deal in principle'));
      expect(prompt, contains('CARD DOMAIN: theathletic.com'));
      expect(prompt, contains('--- ATTACHED ARTICLE ---'));
      expect(prompt, contains('ARTICLE TITLE: Inside the Negotiation'));
      expect(prompt, contains('--- QUOTED POST (Fabrizio Romano) ---'));
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
