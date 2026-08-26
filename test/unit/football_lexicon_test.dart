import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/domain/services/card_prompt_manager.dart';
import 'package:oreamnos/domain/services/football_lexicon.dart';
import 'package:oreamnos/domain/services/generation_prompt_manager.dart';

void main() {
  test('lexicon contains 34+ terms', () {
    expect(FootballLexicon.terms.length, greaterThanOrEqualTo(34));
    expect(FootballLexicon.inlineList, contains('Clean Sheet'));
  });

  test('CardPromptManager system prompt contains lexicon and intents', () {
    final sys = CardPromptManager.buildSystemPrompt();
    expect(sys, contains('Clean Sheet'));
    expect(sys, contains('template_intent'));
    for (final intent in [
      'player_spotlight',
      'headline_quote',
      'top_stats',
      'transfer_news',
      'breaking_news',
      'match_preview',
      'detailed_scoreboard',
      'on_this_day',
      'starting_xi',
      'match_stats_comparison',
      'social_post',
      'rivalry',
      'table_standings',
      'injury_report',
      'contract_expiry',
      'award_nominee',
    ]) {
      expect(sys, contains(intent));
    }
  });

  test('GenerationPromptManager system prompt contains lexicon', () {
    final sys = GenerationPromptManager.buildSystemPrompt();
    expect(sys, contains('Clean Sheet'));
  });
}
