import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';

void main() {
  group('CardPromptManager', () {
    test('systemPrompt contains N/A and template_intent', () {
      final s = CardPromptManager.buildSystemPrompt();
      expect(s, contains('N/A'));
      expect(s, contains('template_intent'));
    });
    test('buildPrompt for each template contains intent', () {
      for (final t in CardTemplate.all) {
        final p = CardPromptManager.buildPrompt(t, 'Test input', false);
        expect(p, contains(t.templateIntent), reason: 'missing for ${t.name}');
        expect(p, contains('INPUT'));
      }
    });
    test('buildPrompt isRefresh adds timestamp', () {
      final a = CardPromptManager.buildPrompt(
        CardTemplate.breakingNews,
        'hello',
        false,
      );
      final b = CardPromptManager.buildPrompt(
        CardTemplate.breakingNews,
        'hello',
        true,
      );
      expect(b.length, greaterThan(a.length));
      expect(b, contains('Refresh'));
    });
    test('buildUserPrompt defaults to socialPost', () {
      final p = CardPromptManager.buildUserPromptForTemplate(
        null,
        'Hello world',
      );
      expect(p, contains('social_post'));
    });
  });
}
