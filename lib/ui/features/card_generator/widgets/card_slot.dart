import 'package:flutter/material.dart';
import 'package:oreamnos/domain/services/card_data_normalizer.dart';

/// Clean hide-on-empty wrapper for canvas renderer elements.
/// Ensures missing, blank, or placeholder fields disappear seamlessly from the canvas.
class CardSlot extends StatelessWidget {
  const CardSlot({
    super.key,
    required this.value,
    this.fieldKey,
    required this.child,
    this.emptyPlaceholder,
  });

  /// The raw value of the field.
  final String? value;

  /// The registered JSON key for this field (used for tap-to-edit focus / accessibility).
  final String? fieldKey;

  /// The widget to render when [value] is present and non-empty.
  final Widget child;

  /// Optional widget to display when [value] is empty (e.g. during specific placeholder modes).
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final cleaned = CardDataNormalizer.cleanValue(value);
    if (cleaned.isNotEmpty) {
      return child;
    }
    if (emptyPlaceholder != null) {
      return emptyPlaceholder!;
    }
    return const SizedBox.shrink();
  }
}
