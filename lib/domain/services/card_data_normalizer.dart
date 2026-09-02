import '../models/card_field.dart';
import '../models/card_field_registry.dart';
import '../models/card_template.dart';

/// Result from [CardDataNormalizer.normalize].
class NormalizedResult {
  const NormalizedResult({required this.json, required this.missingKeys});

  /// The cleaned and normalized JSON payload.
  final Map<String, dynamic> json;

  /// Set of registered required field keys that were missing or empty.
  final Set<String> missingKeys;
}

/// Post-parse normalizer that validates, cleans, and enforces constraints on raw LLM JSON.
class CardDataNormalizer {
  const CardDataNormalizer._();

  static const Set<String> _placeholderTokens = {
    'n/a',
    'na',
    '-',
    '—',
    '--',
    'null',
    'none',
    'tbd',
    'unknown',
    'tiada',
    'undefined',
    'n/d',
    'nil',
  };

  /// Normalizes [rawJson] against [template]'s field descriptors in [CardFieldRegistry].
  static NormalizedResult normalize(
    CardTemplate template,
    Map<String, dynamic> rawJson,
  ) {
    final fields = CardFieldRegistry.fieldsFor(template);
    final cleaned = Map<String, dynamic>.from(rawJson);
    final missing = <String>{};

    for (final field in fields) {
      // 1. Check aliases if primary key is missing or blank
      var val = cleaned[field.key];
      if (val == null || (val is String && val.trim().isEmpty)) {
        for (final alias in field.aliases) {
          final aliasVal = cleaned[alias];
          if (aliasVal != null &&
              (aliasVal is! String || aliasVal.trim().isNotEmpty)) {
            val = aliasVal;
            cleaned[field.key] = val;
            break;
          }
        }
      }

      // 2. Clean string fields and enforce maxChars
      if (val is String) {
        var s = val.trim();
        if (_placeholderTokens.contains(s.toLowerCase())) {
          s = '';
        }
        if (s.length > field.maxChars && field.maxChars > 0) {
          // Truncate cleanly at word boundary if possible
          var cut = s.substring(0, field.maxChars);
          final lastSpace = cut.lastIndexOf(' ');
          if (lastSpace > field.maxChars * 0.6) {
            cut = cut.substring(0, lastSpace);
          }
          s = '$cut…';
        }
        cleaned[field.key] = s;
        val = s;
      }

      // 3. Track missing required fields
      if (field.required) {
        final isBlank =
            val == null ||
            (val is String && val.trim().isEmpty) ||
            (val is List && val.isEmpty) ||
            (val is num &&
                val == 0 &&
                field.type == CardFieldType.number &&
                field.key.contains('Score') == false);
        if (isBlank) {
          missing.add(field.key);
        }
      }
    }

    return NormalizedResult(json: cleaned, missingKeys: missing);
  }

  /// Strips placeholder tokens from a single string value.
  static String cleanValue(String? raw) {
    if (raw == null) return '';
    final s = raw.trim();
    if (_placeholderTokens.contains(s.toLowerCase())) return '';
    return s;
  }
}
