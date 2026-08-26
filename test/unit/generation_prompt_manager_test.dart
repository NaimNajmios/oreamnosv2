import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/generation_prompt_manager.dart';
import 'package:oreamnos/domain/models/curated_post.dart';

void main() {
  group('GenerationPromptManager', () {
    test('buildSystemPrompt includes source when provided', () {
      final s = GenerationPromptManager.buildSystemPrompt(
        sourceUrl: 'https://example.com',
      );
      expect(s, contains('example.com'));
    });
    test('buildSystemPrompt without source has no source line', () {
      final s = GenerationPromptManager.buildSystemPrompt();
      expect(s, contains('Jika tiada URL diberikan'));
      expect(s, isNot(contains('Sumber input ialah URL')));
    });
    test('buildUserPrompt handles string', () {
      final p = GenerationPromptManager.buildUserPrompt('Hello news');
      expect(p, contains('Hello news'));
    });
    test('buildUserPrompt handles ExtractedArticle', () {
      const article = ExtractedArticle(
        text: 'Article text',
        url: 'https://ex.com',
        domain: 'ex.com',
      );
      final p = GenerationPromptManager.buildUserPrompt(article);
      expect(p, contains('Article text'));
    });
  });
}
