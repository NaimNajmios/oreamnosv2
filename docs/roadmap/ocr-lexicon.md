# Roadmap — OCR + Lexicon

## FootballOcrParser

> `lib/data/services/ml_kit_vision_extractor.dart:11` `google_mlkit_text_recognition` `script:latin` returns `recognizedText.text` raw. Android `project_context 22471 object FootballOcrParser.formatForPrompt` does score normalization, fixture date, table tidying.

**Plan:** Port `FootballOcrParser` → `lib/domain/services/football_ocr_parser.dart`, call `formatForPrompt(rawText)` inside `MLKitVisionExtractor.extractText:11` before `return`. Add `test/unit/football_ocr_parser_test.dart`.

## Lexicon Divergence

> `CardPromptManager:13` 34 terms (`Clean Sheet, Offside, Hat-trick… Overhead Kick`) + `CRITICAL RULE 3 N/A:14`; `GenerationPromptManager:11` builds Malay prompt but no lexicon (`lib/domain/services/generation_prompt_manager.dart:11`).

> Dead `prompt_manager.dart:7` `PromptManager.buildSystemPrompt(tone, defaultHashtags)`.

**Plan:** Extract `lib/domain/services/football_lexicon.dart` shared constant; inject into both managers; delete `prompt_manager.dart`; update `GenerationPromptManager.buildSystemPrompt:11` to include lexicon paragraph; add snapshot `generation_prompt_manager_test`.

