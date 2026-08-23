import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monospace text input field matching the Neo-Editorial design.
/// Uses JetBrains Mono for the input text (matching Android's NeoInput).
class NeoInput extends StatelessWidget {
  const NeoInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: theme.colorScheme.onSurface.withAlpha(102),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
