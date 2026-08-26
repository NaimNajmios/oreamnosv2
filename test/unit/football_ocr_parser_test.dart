import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/football_ocr_parser.dart';

void main() {
  group('FootballOcrParser', () {
    test('normalizes scores', () {
      expect(
        FootballOcrParser.formatForPrompt('JDT 2 - 1 Selangor'),
        contains('2-1'),
      );
      expect(FootballOcrParser.formatForPrompt('Score 3 : 0'), contains('3-0'));
    });

    test('preserves paragraph breaks', () {
      const raw = 'First para line one\nSecond line\n\nSecond para';
      final out = FootballOcrParser.formatForPrompt(raw);
      expect(out.split('\n\n').length, 2);
    });

    test('empty input returns empty', () {
      expect(FootballOcrParser.formatForPrompt('   '), isEmpty);
    });

    test('normalizes pipes', () {
      expect(
        FootballOcrParser.formatForPrompt('Team | P | W'),
        contains('Team | P | W'),
      );
    });
  });
}
