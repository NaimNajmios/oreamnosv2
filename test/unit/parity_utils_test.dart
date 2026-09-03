import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/utils/readability_utils.dart';
import 'package:oreamnos/domain/services/generation_prompt_manager.dart';
import 'package:oreamnos/domain/services/response_cleanup.dart';
import 'package:oreamnos/data/services/web_scraper_service.dart';

void main() {
  group('ReadabilityUtils (Android parity)', () {
    test('countWords handles null/blank/prose', () {
      expect(ReadabilityUtils.countWords(null), 0);
      expect(ReadabilityUtils.countWords('   '), 0);
      expect(ReadabilityUtils.countWords('JDT menang tiga kosong'), 4);
    });

    test('calculateFleschKincaidGradeLevel simple vs complex', () {
      final simple = ReadabilityUtils.calculateFleschKincaidGradeLevel(
        'JDT menang. Gol dijaringkan awal. Penyokong bersorak.',
      );
      final complex = ReadabilityUtils.calculateFleschKincaidGradeLevel(
        'The implementation of comprehensive tactical restructuring fundamentally transformed the organizational paradigm of contemporary football methodology.',
      );
      expect(simple, greaterThanOrEqualTo(0.0));
      expect(complex, greaterThan(simple));
      expect(ReadabilityUtils.calculateFleschKincaidGradeLevel(null), 0.0);
    });

    test('splitLongParagraphs keeps short text intact', () {
      const text = 'Short paragraph here.';
      expect(
        ReadabilityUtils.splitLongParagraphs(text, maxWordsPerParagraph: 40),
        text,
      );
    });
  });

  group('Prompt detectors (Android parity)', () {
    test('containsQuotes detects ascii + curly quotes', () {
      expect(GenerationPromptManager.containsQuotes('dia kata "hello"'), true);
      expect(
        GenerationPromptManager.containsQuotes('katanya \u2018ok\u2019'),
        true,
      );
      expect(GenerationPromptManager.containsQuotes('tiada petikan'), false);
      expect(GenerationPromptManager.containsQuotes(null), false);
    });

    test('containsBulletPoints year guard (2024. not a list)', () {
      expect(
        GenerationPromptManager.containsBulletPoints(
          'Pada 2024. musim bermula',
        ),
        false,
      );
      expect(
        GenerationPromptManager.containsBulletPoints('1. item satu'),
        true,
      );
      expect(GenerationPromptManager.containsBulletPoints('999. item'), true);
      expect(GenerationPromptManager.containsBulletPoints('1000. item'), false);
      expect(GenerationPromptManager.containsBulletPoints('- item'), true);
      expect(GenerationPromptManager.containsBulletPoints('• item'), true);
      expect(GenerationPromptManager.containsBulletPoints('a) item'), true);
    });

    test('isLongTechnicalContent needs length + 5 keywords', () {
      expect(GenerationPromptManager.isLongTechnicalContent('short'), false);
      final technical =
          ('formation tactical pressing possession xg expected goals pass completion ' *
          60);
      expect(GenerationPromptManager.isLongTechnicalContent(technical), true);
      final longPlain =
          ('cerita bola sepak yang sangat panjang dan menarik ' * 100);
      expect(GenerationPromptManager.isLongTechnicalContent(longPlain), false);
    });

    test('lengthRange multipliers short/medium/long', () {
      final short = lengthRange(1000, 'short');
      expect(short.minChars, 200);
      expect(short.maxChars, 300);
      final medium = lengthRange(1000, 'medium');
      expect(medium.minChars, 400);
      expect(medium.maxChars, 600);
      final long = lengthRange(1000, 'long');
      expect(long.minChars, 700);
      expect(long.maxChars, 900);
      // Floors for tiny inputs.
      final tiny = lengthRange(10, 'short');
      expect(tiny.minChars, 50);
      expect(tiny.maxChars, 100);
    });

    test('buildSystemPrompt adapts to length + technical + bullets', () {
      final technical =
          ('The 4-3-3 formation with high press and counter-attack transition shape pressing possession ' *
          60);
      final s = GenerationPromptManager.buildSystemPrompt(
        length: 'short',
        sourceText: technical,
      );
      expect(s, contains('concise and brief'));
      expect(s, contains('20-30%'));
      expect(s, contains('TECHNICAL ANALYSIS'));
    });

    test('buildRefinementPrompt maps keys + custom pills', () {
      final p = GenerationPromptManager.buildRefinementPrompt(
        originalPost: 'JDT menang 3-0.',
        refinements: ['rephrase', 'recheck_flow', 'Buat lebih santai'],
        includeSource: false,
      );
      expect(p, contains('Rephrase:'));
      expect(p, contains('Recheck Flow:'));
      expect(p, contains('Custom Instruction: Buat lebih santai'));
      expect(p, contains("Do NOT include any 'Sumber:'"));
    });
  });

  group('ResponseCleanup (Android parity)', () {
    test('removeSourceCitation strips Sumber lines', () {
      const text = 'Berita baik.\nSumber: Berita Harian';
      expect(ResponseCleanup.removeSourceCitation(text), 'Berita baik.');
    });

    test('cleanUpResponse normalizes bullets + newlines + phrases', () {
      final long =
          'Laporan penuh perlawanan yang berlangsung malam tadi di stadium.\n'
          '- Gol pertama dijaringkan pada minit kedua puluh tiga perlawanan.\n'
          'Saya cuba untuk melaporkan dengan baik sekali.';
      final cleaned = ResponseCleanup.cleanUpResponse(long);
      expect(cleaned, contains('• Gol pertama'));
      expect(cleaned, isNot(contains('Saya cuba')));
    });

    test('cleanUpResponse guards short stubs', () {
      expect(ResponseCleanup.cleanUpResponse('pendek'), 'pendek');
    });

    test('cleanUpResponseWithMarkdown strips asterisks', () {
      final long =
          'Laporan penuh perlawanan yang berlangsung malam tadi di stadium dengan penuh. '
          '**Gol hebat** dijaringkan lewat permainan oleh penyerang utama pasukan.';
      expect(
        ResponseCleanup.cleanUpResponseWithMarkdown(long),
        contains('Gol hebat'),
      );
    });
  });

  group('WebScraperService url + cleaning parity', () {
    test('isUrl accepts scheme, www, bare domains; rejects junk', () {
      expect(WebScraperService.isUrl('https://example.com/a'), true);
      expect(WebScraperService.isUrl('http://example.com'), true);
      expect(WebScraperService.isUrl('www.example.com/news'), true);
      expect(WebScraperService.isUrl('example.com/news'), true);
      expect(WebScraperService.isUrl('not a url'), false);
      expect(WebScraperService.isUrl('abc'), false);
      expect(WebScraperService.isUrl('user@example'), false);
    });

    test('normalizeUrl adds https when missing', () {
      expect(
        WebScraperService.normalizeUrl('example.com/a'),
        'https://example.com/a',
      );
      expect(
        WebScraperService.normalizeUrl('https://example.com/a'),
        'https://example.com/a',
      );
    });

    test('cleanTextPreserveParagraphs collapses runs + strips promo', () {
      final out = WebScraperService.cleanTextPreserveParagraphs(
        'Para satu.\n\n\n\nPara dua.\nShare this article with friends for more updates on the match tonight live.',
      );
      expect(out.contains('\n\n\n'), false);
      expect(out, contains('Para satu.'));
    });
  });
}
