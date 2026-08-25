import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/json_cleaner.dart';

void main() {
  group('JsonCleaner', () {
    test('strips ```json fence', () {
      const input = '```json\n{"headline":"Hi"}\n```';
      expect(JsonCleaner.clean(input), '{"headline":"Hi"}');
    });
    test('strips ``` fence', () {
      const input = '```\n{"a":1}\n```';
      expect(JsonCleaner.clean(input), '{"a":1}');
    });
    test('extracts first {...} with preamble', () {
      const input = 'Here is JSON: {"headline":"Test"} trailing';
      expect(JsonCleaner.clean(input), '{"headline":"Test"}');
    });
    test('decode valid json', () {
      const input = '{"headline":"Hello","subtext":"World"}';
      final m = JsonCleaner.decode(input);
      expect(m['headline'], 'Hello');
    });
    test('decode with fence and preamble', () {
      const input = 'Sure:\n```json\n{"headline":"A","subtext":"B"}\n```\nThanks';
      final m = JsonCleaner.decode(input);
      expect(m['subtext'], 'B');
    });
  });
}
