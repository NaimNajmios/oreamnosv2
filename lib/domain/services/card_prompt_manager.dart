import 'package:oreamnos/data/models/ai_provider.dart';
import '../../domain/models/card_brief.dart';

class CardPromptManager {
  static String buildSystemPrompt() {
    return '''You are a structured data extractor for football (soccer) companion visuals.
Your ONLY output must be a single valid JSON object.
Do NOT include any explanation, preamble, markdown, code fences, or text outside the JSON.
Start your response with { and end it with }.
The card is a LIGHTWEIGHT companion to a social caption — not a full article. Keep it sparse and punchy.
CRITICAL RULE 1: Translate ALL extracted text values into Malaysian Malay (Bahasa Malaysia) EXCEPT for proper nouns like player names, club names, or tournament acronyms.
CRITICAL RULE 2: ALWAYS use these accepted English football terms instead of making up stiff direct translations in Bahasa Malaysia. Do NOT translate:
'Clean Sheet', 'Offside', 'Hat-trick', 'Tackle', 'Assist', 'Playmaker', 'Derby', 'Comeback', 'Winger', 'Striker', 'Midfielder', 'Defender', 'Full-back', 'Center-back', 'Goalkeeper', 'Free-kick', 'Penalty', 'Corner Kicks', 'VAR', 'Counter-attack', 'Pressing', 'Cross', 'Header', 'Nutmeg', 'Dribble', 'Volley', 'Bicycle Kick', 'Man of the Match', 'Golden Boot', 'Pitch', 'Box-to-box', 'Sweeper', 'Target Man', 'False Nine', 'High Press', 'Through Ball', 'Overhead Kick'.
CRITICAL RULE 3: If a specific piece of information is NOT explicitly mentioned, return empty string "" for that field. Do NOT guess or use placeholders like 'N/A', '-', '—'.
CRITICAL RULE 4: Headline MUST be ≤60 characters. Subtext MUST be one sentence ≤90 characters. MicroStat is optional short badge (≤24 chars) or "" if none stands out.''';
  }

  /// Sparse companion schema — headline + hook + optional proof.
  /// [brief] is the light input (headline + first sentence). We polish into visual copy.
  static String buildUserPrompt(CardBrief brief) {
    final schema = _sparseSchema();
    final context = brief.promptContext.isEmpty ? '(empty)' : brief.promptContext;
    return '$schema\n\nINPUT (headline + hook):\n$context\n\nRespond with ONLY the JSON object, starting with {';
  }

  /// Back-compat: template param is now ignored — all templates consume the same sparse JSON.
  /// Kept so curators compile without breakage; new code should call buildUserPrompt(brief).
  static String buildUserPromptForTemplate(dynamic template, String generatedText) {
    final fakeBrief = CardBrief(
      headline: generatedText.split('\n').first.trim(),
      subtext: generatedText.trim(),
      provider: AiProvider.gemini,
      modelId: '',
    );
    return buildUserPrompt(fakeBrief);
  }

  static String _sparseSchema() {
    return '''
Polish the INPUT into a lightweight social companion card.
Return ONLY a JSON object with this exact structure (write values in Bahasa Malaysia per rules):
{
  "headline": "Tajuk hook padat (maks 60 aksara, UPPERCASE-ready)",
  "subtext": "Satu ayat umpan ringan (maks 90 aksara, satu ayat sahaja)",
  "microStat": "Satu badge ringkas (maks 24 aksara) atau '' jika tiada yang menarik — contoh: 'Hat-trick • 90'"
}''';
  }
}

