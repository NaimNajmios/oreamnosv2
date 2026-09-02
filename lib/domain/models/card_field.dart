/// Field types supported by the Card Studio Field Registry.
enum CardFieldType { text, number, rating, money, list, quote, date, bool_ }

/// Metadata descriptor for a single template field.
/// Serves as the single source of truth for prompts, extraction, normalization, and Studio Deck UI.
class CardFieldDescriptor {
  const CardFieldDescriptor({
    required this.key,
    required this.label,
    required this.type,
    this.maxChars = 40,
    this.required = false,
    this.group = 'primary',
    this.aiHint,
    this.aliases = const [],
  });

  /// Canonical JSON key — the contract between AI prompt, extractor, and CardData.
  final String key;

  /// Human-readable label displayed in Studio Deck text panel.
  final String label;

  /// Field data type.
  final CardFieldType type;

  /// Max character count limit enforced in prompt & normalizer.
  final int maxChars;

  /// If true, normalizer tracks this as "missing" if left blank by AI.
  final bool required;

  /// Display group in Studio Deck: 'primary' | 'secondary' | 'optional'.
  final String group;

  /// Specific instruction for AI extractor prompt.
  final String? aiHint;

  /// Alternative keys the LLM might output that should map to [key].
  final List<String> aliases;
}
