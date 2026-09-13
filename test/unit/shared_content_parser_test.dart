import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/utils/shared_content_parser.dart';
import 'package:oreamnos/core/utils/url_detector.dart';

void main() {
  group('SharedContentParser', () {
    test('parses pure Twitter/X status URL', () {
      const input = 'https://x.com/jack/status/20';
      final parsed = SharedContentParser.parse(input);

      expect(parsed.isPureUrl, isTrue);
      expect(parsed.primaryUrl, 'https://x.com/jack/status/20');
      expect(parsed.urlType, UrlType.twitterStatus);
      expect(parsed.accompanyingText, isEmpty);
      expect(parsed.displayInput, 'https://x.com/jack/status/20');
    });

    test('parses Twitter/X status URL with tracking parameters and commentary', () {
      const input =
          'Check out this update: https://twitter.com/FabrizioRomano/status/123456789?s=20&t=abcdef';
      final parsed = SharedContentParser.parse(input);

      expect(parsed.isPureUrl, isFalse);
      expect(
        parsed.primaryUrl,
        'https://twitter.com/FabrizioRomano/status/123456789',
      );
      expect(parsed.urlType, UrlType.twitterStatus);
      expect(parsed.accompanyingText, 'Check out this update:');
      expect(
        parsed.displayInput,
        'Check out this update:\nhttps://twitter.com/FabrizioRomano/status/123456789',
      );
    });

    test('parses web article share with multi-line title', () {
      const input =
          'Breaking News: Major transfer agreed\nhttps://theathletic.com/football/arsenal-deal/?utm_source=twitter&utm_medium=social';
      final parsed = SharedContentParser.parse(input);

      expect(parsed.isPureUrl, isFalse);
      expect(
        parsed.primaryUrl,
        'https://theathletic.com/football/arsenal-deal/',
      );
      expect(parsed.urlType, UrlType.article);
      expect(parsed.accompanyingText, 'Breaking News: Major transfer agreed');
    });

    test('strips trailing punctuation and brackets from URLs', () {
      const input =
          'Read the report at (https://bbc.com/sport/football/12345). Amazing!';
      final parsed = SharedContentParser.parse(input);

      expect(parsed.primaryUrl, 'https://bbc.com/sport/football/12345');
      expect(parsed.urlType, UrlType.article);
      expect(parsed.accompanyingText, 'Read the report at ( Amazing!');
    });

    test('handles plain text input with no URL', () {
      const input =
          'Arsenal lead Chelsea 2-0 after an early brace from Saka in the first half.';
      final parsed = SharedContentParser.parse(input);

      expect(parsed.primaryUrl, isNull);
      expect(parsed.urlType, UrlType.notUrl);
      expect(parsed.isPureUrl, isFalse);
      expect(parsed.accompanyingText, input);
      expect(parsed.displayInput, input);
    });

    test('handles empty input', () {
      final parsed = SharedContentParser.parse('   ');
      expect(parsed.primaryUrl, isNull);
      expect(parsed.urlType, UrlType.notUrl);
      expect(parsed.displayInput, isEmpty);
    });

    test('supports mobile.twitter.com and fixupx.com variants', () {
      final parsed1 = SharedContentParser.parse(
        'https://mobile.twitter.com/user/status/555',
      );
      expect(parsed1.urlType, UrlType.twitterStatus);

      final parsed2 = SharedContentParser.parse(
        'https://fixupx.com/user/status/777',
      );
      expect(parsed2.urlType, UrlType.twitterStatus);
    });
  });
}
