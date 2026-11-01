import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/facebook_text_formatter.dart';

void main() {
  group('FacebookTextFormatter.toPlainText', () {
    test('strips bold and italic markers', () {
      expect(
        FacebookTextFormatter.toPlainText(
          '**JDT 3 - 0 Kedah** in the _Super League_!',
        ),
        'JDT 3 - 0 Kedah in the Super League!',
      );
    });

    test('strips heading markers only at line start with a space', () {
      expect(
        FacebookTextFormatter.toPlainText('# Match Report\n\nLine two.'),
        'Match Report\n\nLine two.',
      );
      // Hashtags must survive, even at line start.
      expect(
        FacebookTextFormatter.toPlainText('#HashtagLine\n#FAM'),
        '#HashtagLine\n#FAM',
      );
    });

    test('keeps hashtags alongside removed headings', () {
      expect(
        FacebookTextFormatter.toPlainText('## Penalties\nGoal #3 in minute #2.'),
        'Penalties\nGoal #3 in minute #2.',
      );
    });

    test('converts links to label + raw URL', () {
      expect(
        FacebookTextFormatter.toPlainText(
          'Source: [The Star](https://www.thestar.com.my/article)',
        ),
        'Source: The Star (https://www.thestar.com.my/article)',
      );
    });

    test('bare-link markdown collapses to the URL', () {
      expect(
        FacebookTextFormatter.toPlainText(
          r'[](https://example.com/x)',
        ),
        'https://example.com/x',
      );
    });

    test('label equal to URL collapses to the URL', () {
      expect(
        FacebookTextFormatter.toPlainText(
          '[](https://example.com/x)',
        ),
        'https://example.com/x',
      );
    });

    test('underscore emphasis only across word boundaries', () {
      // Emphasis survives when the underscores hug a whole word.
      expect(FacebookTextFormatter.toPlainText('_Safuwan_ scores'),
          'Safuwan scores');
      // snake_case and in-hashtag underscores survive.
      expect(FacebookTextFormatter.toPlainText('man_of_the_match'),
          'man_of_the_match');
      expect(
        FacebookTextFormatter.toPlainText('#man_of_the_match trended'),
        '#man_of_the_match trended',
      );
    });

    test('strips blockquote markers and horizontal rules', () {
      const input = '> Verbatim from the club\n\n---\nNext line';
      expect(
        FacebookTextFormatter.toPlainText(input),
        'Verbatim from the club\n\nNext line',
      );
    });

    test('strips inline code and code-block fences', () {
      expect(
        FacebookTextFormatter.toPlainText('The `formation` held.'),
        'The formation held.',
      );
    });

    test('collapses consecutive blank lines to one', () {
      expect(
        FacebookTextFormatter.toPlainText('A\n\n\n\nB\n\n\nC'),
        'A\n\nB\n\nC',
      );
    });

    test('trims trailing whitespace per line and at the ends', () {
      expect(
        FacebookTextFormatter.toPlainText('  A   \n  B  \n'),
        'A\nB',
      );
    });

    test('a realistic curated post comes out clean', () {
      const input = '**FT: JDT 4 - 1 Terengganu** 🏆\n\n'
          '# Match Report\n'
          'Martin hat-trick seals the _Super League_ crown.\n\n'
          '[Full story](https://example.com/jdt) — #FAM #JDT';
      expect(
        FacebookTextFormatter.toPlainText(input),
        'FT: JDT 4 - 1 Terengganu 🏆\n\n'
            'Match Report\n'
            'Martin hat-trick seals the Super League crown.\n\n'
            'Full story (https://example.com/jdt) — #FAM #JDT',
      );
    });
  });
}
