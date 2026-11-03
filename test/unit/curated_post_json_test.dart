import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/domain/services/json_cleaner.dart';

/// Regression: a model that nests the whole document inside `body`
/// (`{"title":…,"body":"{\"title\":…,\"body\":…}"}`) used to render raw
/// JSON in the generated post.
void main() {
  group('CuratedPost double-encoded body', () {
    test('unwraps a JSON document nested inside body', () {
      final inner = {
        'title': 'Arsenal Sasar Eli Junior Kroupi',
        'body':
            'Kelas Liga Perdana Inggeris, Arsenal dilaporkan meletakkan '
            'penyerang Bournemouth, Eli Junior Kroupi.\n\n'
            'Pengurus Arsenal, Mikel Arteta, berhasrat untuk mempersiapkan '
            'jenteranya.',
        'hashtags': ['FAM', 'Arsenal'],
        'source': {'label': 'Liga Perdana', 'url': 'https://example.com/a'},
      };
      final post = CuratedPost.fromJson({
        'title': 'Arsenal Sasar Eli Junior Kroupi',
        'body': jsonEncode(inner),
      });

      expect(post.title, 'Arsenal Sasar Eli Junior Kroupi');
      expect(post.bodyMarkdown, isNot(contains('{"title"')));
      expect(post.bodyMarkdown, startsWith('Kelas Liga Perdana Inggeris'));
      expect(post.hashtags, ['FAM', 'Arsenal']);
      expect(post.source.label, 'Liga Perdana');
    });

    test('keeps the outer title when the inner document omits it', () {
      final post = CuratedPost.fromJson({
        'title': 'Outer Headline',
        'body': jsonEncode({'body': 'Inner body text only.'}),
      });

      expect(post.title, 'Outer Headline');
      expect(post.bodyMarkdown, contains('Inner body text only.'));
      expect(post.bodyMarkdown, isNot(contains('{')));
    });

    test('does not touch a normal body that merely starts with a brace-free '
        'sentence', () {
      const body = 'Satu perenggan biasa yang tiada JSON di dalamnya.';
      final post = CuratedPost.fromJson({'title': 'Tajuk', 'body': body});
      expect(post.bodyMarkdown, body);
    });

    test('leaves an unbalanced brace body alone instead of throwing', () {
      const body = '{ bukan JSON yang sah';
      final post = CuratedPost.fromJson({'title': 'Tajuk', 'body': body});
      expect(post.bodyMarkdown, contains('bukan JSON yang sah'));
    });

    test('converts literal \\n escapes into real paragraphs', () {
      const body =
          r'Perenggan pertama.\n\nPerenggan kedua dengan butiran tambahan.';
      final post = CuratedPost.fromJson({'title': 'Tajuk', 'body': body});
      expect(post.bodyMarkdown, isNot(contains(r'\n')));
      expect(post.bodyMarkdown, contains('Perenggan pertama.'));
      expect(
        post.bodyMarkdown.split(RegExp(r'\n+')).length,
        greaterThanOrEqualTo(2),
      );
    });

    test('unwraps nested JSON that still has literal newline escapes', () {
      final inner =
          '{"title":"Tajuk Dalam","body":"Baris satu.\\\\n\\\\nBaris dua."}';
      final post = CuratedPost.fromJson({'title': 'Tajuk Luar', 'body': inner});

      expect(post.bodyMarkdown, isNot(contains('body')));
      expect(post.bodyMarkdown, contains('Baris satu.'));
      expect(post.bodyMarkdown, contains('Baris dua.'));
    });
  });

  group('JsonCleaner double-encoded response', () {
    test('decodes a document returned as a JSON string', () async {
      final encoded = jsonEncode(
        jsonEncode({'title': 'Tajuk', 'body': 'Isi kandungan.'}),
      );
      final map = await JsonCleaner.decodeIsolate(encoded);
      expect(map['title'], 'Tajuk');
      expect(map['body'], 'Isi kandungan.');
    });

    test('throws for a plain string that is not a document', () {
      expect(() => JsonCleaner.decode('"just text"'), throwsFormatException);
    });
  });
}
