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

  group('JsonCleaner.repairTruncated (MAX_TOKENS cut)', () {
    // Real failure: the response stops mid-sentence with no closing quote or
    // brace, so the app fell back to raw JSON in the generated post.
    const truncated =
        '{"title":"Arsenal Sasar Eli Junior Kroupi dan Kenan Yildiz Bagi '
        'Jendela Perpindahan Januari","body":"Kelab Liga Perdana Inggeris, '
        'Arsenal, dilaporkan meletakkan penyerang Bournemouth, Eli Junior '
        'Kroupi, serta Winger Juventus, Kenan Yildiz, dalam senarai sasaran '
        'utama mereka menjelang jendela perpindahan Januari.\\n\\nPengurus '
        'Arsenal, Mikel Arteta, berhasrat untuk memperkasakan jentera '
        'serangan selepas gagal mendapatkan beberapa sasaran berprofil tinggi '
        'pada musim panas lalu.\\n\\nKroupi, yang merupakan pemain '
        'antarabangsa Perancis Bawah-21 tahun, sebelum ini mengalami '
        'kecederaan retak tulang kaki pada pramusim hingga tersisih selama '
        'tiga bulan.\\n\\nWalaupun turut diminati kelab seperti Manchester '
        'United, Tottenham, Bayern Munich dan Paris';

    test('recovers a parseable document', () {
      final map = JsonCleaner.repairTruncated(truncated);
      expect(map, isNotNull);
      expect(map!['title'], startsWith('Arsenal Sasar'));
      expect(map['body'], isA<String>());
    });

    test('drops the half-written final sentence', () {
      final body = JsonCleaner.repairTruncated(truncated)!['body'] as String;
      expect(body, contains('tersisih selama tiga bulan.'));
      expect(
        body,
        isNot(contains('Walaupun turut diminati')),
        reason: 'the incomplete sentence must be discarded',
      );
    });

    test('repaired text renders prose, not raw JSON', () {
      final post = CuratedPost.fromJson(
        JsonCleaner.repairTruncated(truncated)!,
      );
      expect(
        post.title,
        'Arsenal Sasar Eli Junior Kroupi dan Kenan Yildiz '
        'Bagi Jendela Perpindahan Januari',
      );
      expect(post.bodyMarkdown, isNot(contains('{"title"')));
      expect(post.bodyMarkdown, isNot(contains(r'\n')));
      expect(post.bodyMarkdown, contains('Kelab Liga Perdana Inggeris'));
    });

    test('repairs a cut between fields (dangling key and comma)', () {
      final map = JsonCleaner.repairTruncated(
        '{"title":"Tajuk","body":"Isi.","hashtags":["FAM","Ars',
      );
      expect(map, isNotNull);
      expect(map!['title'], 'Tajuk');
      expect(map['body'], 'Isi.');
    });

    test('repairs a cut right after a colon', () {
      final map = JsonCleaner.repairTruncated('{"title":"Tajuk","body":');
      expect(map, isNotNull);
      expect(map!['title'], 'Tajuk');
    });

    test('returns null for non-JSON text', () {
      expect(JsonCleaner.repairTruncated('Tiada JSON di sini.'), isNull);
    });
  });
}
