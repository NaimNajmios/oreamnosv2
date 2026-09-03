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
      expect(s, contains('If no URL is provided'));
      expect(s, isNot(contains('Input source URL is:')));
    });

    test('buildSystemPrompt adds Fan Mode instruction when enabled', () {
      final s1 = GenerationPromptManager.buildSystemPrompt(
        isFanModeEnabled: true,
        fanClubName: 'Arsenal',
      );
      expect(s1, contains('Act as a fan page representing Arsenal'));
      expect(s1, isNot(contains('neutral, unbiased')));

      final s2 = GenerationPromptManager.buildSystemPrompt(
        isFanModeEnabled: true,
      );
      expect(s2, contains('Act as a fan page representing the club mentioned'));
    });

    test('buildSystemPrompt adds Keep Structure instruction when enabled', () {
      final s = GenerationPromptManager.buildSystemPrompt(keepStructure: true);
      expect(
        s,
        contains(
          'Keep the exact same structure, paragraphing, and bullet points as the source text',
        ),
      );
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

    test('geminiResponseSchema strips additionalProperties recursively', () {
      final schema = GenerationPromptManager.geminiResponseSchema;
      bool hasAdditional(dynamic node) {
        if (node is Map) {
          if (node.containsKey('additionalProperties')) return true;
          return node.values.any(hasAdditional);
        }
        if (node is List) return node.any(hasAdditional);
        return false;
      }

      expect(hasAdditional(schema), isFalse);
      // Structure retained for Gemini structured output.
      expect(schema['type'], 'object');
      final props = schema['properties'] as Map;
      expect(props.keys, containsAll(['title', 'body', 'source']));
      expect(schema['required'], containsAll(['title', 'body', 'source']));
      final source = props['source'] as Map;
      expect((source['properties'] as Map).keys, containsAll(['label', 'url']));
    });

    test('jsonSchema keeps additionalProperties for OpenAI strict mode', () {
      final schema = GenerationPromptManager.jsonSchema;
      expect(schema['additionalProperties'], isFalse);
    });
  });
}
