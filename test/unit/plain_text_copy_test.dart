import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/ui/core/widgets/typewriter_markdown.dart';

void main() {
  group('Paste-safe plain text (WYSIWYG copy)', () {
    test('fromJson normalizes dash/star/numbered markers to •', () {
      final post = CuratedPost.fromJson({
        'title': 'T',
        'body': 'Intro:\n- 68 touches\n* 5 duels won\n1. 3 chances\n1 goal',
        'source': {'label': '', 'url': ''},
      });
      expect(post.bodyMarkdown, contains('• 68 touches'));
      expect(post.bodyMarkdown, contains('• 5 duels won'));
      expect(post.bodyMarkdown, contains('• 3 chances'));
      expect(post.bodyMarkdown, isNot(contains('\n- ')));
      expect(post.bodyMarkdown, isNot(contains('\n* ')));
    });

    test('toPlainText strips markdown the renderer hides', () {
      const raw = 'Intro\n\n**bold** and `code` here\n- item one\n> quoted';
      final plain = CuratedPost.toPlainText(raw);
      expect(plain, isNot(contains('**')));
      expect(plain, isNot(contains('`')));
      expect(plain, contains('bold and code here'));
      expect(plain, contains('• item one'));
    });

    test('toPlainTextFiltered keeps hashtags newline-per-tag (option B)', () {
      final post = CuratedPost.fromJson({
        'title': 'Statistik Permainan Jude Bellingham Lawan Napoli',
        'body': 'Permainan Jude Bellingham mengikut angka menentang Napoli:\n• 68 sentuhan\n• 5 duel dimenangi',
        'hashtags': ['COYG', 'NN24'],
        'source': {'label': '', 'url': ''},
      });
      final plain = post.toPlainTextFiltered(
        showTitle: true,
        showHashtags: true,
        showSource: false,
      );
      expect(plain, contains('• 68 sentuhan'));
      expect(plain, contains('#COYG\n#NN24'));
      expect(plain, isNot(contains('**')));
    });

    test('Bellingham golden case: 6 bullets survive paste as •', () {
      final post = CuratedPost.fromJson({
        'title': 'Statistik Permainan Jude Bellingham Lawan Napoli',
        'body': 'Permainan Jude Bellingham mengikut angka menentang Napoli:\n- 100% ketepatan hantaran di sepertiga akhir\n- 68 sentuhan\n- 5 duel dimenangi\n- 3 peluang dicipta\n- 1 gol\n- 1 assist\n\nMemang kelas tersendiri.',
        'source': {'label': '', 'url': ''},
      });
      final plain = post.toPlainTextFiltered();
      for (final line in [
        '• 100% ketepatan hantaran di sepertiga akhir',
        '• 68 sentuhan',
        '• 5 duel dimenangi',
        '• 3 peluang dicipta',
        '• 1 gol',
        '• 1 assist',
      ]) {
        expect(plain, contains(line));
      }
      expect(plain, contains('Memang kelas tersendiri.'));
    });
  });

  group('TypewriterMarkdown.normalizeForDisplay', () {
    test('maps • to markdown list without doubling newlines', () {
      const input = 'Intro:\n• 68 sentuhan\n• 5 duel dimenangi';
      final out = TypewriterMarkdown.normalizeForDisplay(input);
      expect(out, contains('Intro:\n- 68 sentuhan\n- 5 duel dimenangi'));
      expect(out, isNot(contains('\n\n- ')));
    });

    test('collapses 3+ newlines but keeps paragraph breaks', () {
      const input = 'Para one\n\n\nPara two';
      final out = TypewriterMarkdown.normalizeForDisplay(input);
      expect(out, 'Para one\n\nPara two');
    });
  });
}
