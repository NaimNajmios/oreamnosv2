import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/card_field.dart';
import 'package:oreamnos/domain/models/card_field_registry.dart';

import '../../view_models/card_generator_view_model.dart';

class TextPanel extends ConsumerWidget {
  const TextPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);

    if (state.cardData == null) return const SizedBox();

    final json = state.cardData!.toJson();
    final fields = CardFieldRegistry.fieldsFor(state.selectedTemplate);
    final editableFields = fields
        .where(
          (f) => f.type != CardFieldType.list && f.type != CardFieldType.bool_,
        )
        .toList();
    final groups = ['primary', 'secondary', 'optional'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: FilledButton.tonalIcon(
            onPressed: state.isExtracting
                ? null
                : () async {
                    await notifier.regenerateAllFields();
                  },
            icon: state.isExtracting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              state.isExtracting ? 'Regenerating...' : 'AI Rewrite All',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
          ),
        ),
        for (final group in groups) ...[
          if (editableFields.any((f) => f.group == group)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Row(
                children: [
                  Text(
                    group.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            ...editableFields.where((f) => f.group == group).map((field) {
              final rawVal = json[field.key];
              final initialVal = rawVal == null ? '' : rawVal.toString();
              final isMissing = state.missingFields.contains(field.key);

              return DynamicCardField(
                key: ValueKey('${state.cardData!.runtimeType}_${field.key}'),
                fieldKey: field.key,
                label: field.label,
                maxLen: field.maxChars > 0 ? field.maxChars : 120,
                isRequired: field.required,
                isMissing: isMissing,
                aiHint: field.aiHint,
                initialValue: initialVal,
                onChanged: (v) => notifier.updateCardField(field.key, v),
                isRewriting: state.isRewriting(field.key),
                onRewrite: () async {
                  final brief = state.brief;
                  if (brief == null) return;
                  final prefs = getIt<PreferencesService>();
                  final apiKey = await prefs.getApiKey(brief.provider);
                  if (apiKey == null || apiKey.isEmpty) return;
                  notifier.rewriteDynamicField(
                    fieldKey: field.key,
                    provider: brief.provider,
                    modelId: brief.modelId,
                    apiKey: apiKey,
                  );
                },
              );
            }),
          ],
        ],
      ],
    );
  }
}

class DynamicCardField extends StatefulWidget {
  final String fieldKey;
  final String label;
  final int maxLen;
  final bool isRequired;
  final bool isMissing;
  final String? aiHint;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onRewrite;
  final bool isRewriting;

  const DynamicCardField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.maxLen,
    required this.isRequired,
    required this.isMissing,
    this.aiHint,
    required this.initialValue,
    required this.onChanged,
    required this.onRewrite,
    required this.isRewriting,
  });

  @override
  State<DynamicCardField> createState() => _DynamicCardFieldState();
}

class _DynamicCardFieldState extends State<DynamicCardField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: (widget.initialValue == 'N/A' || widget.initialValue == '-')
          ? ''
          : widget.initialValue,
    );
  }

  @override
  void didUpdateWidget(DynamicCardField old) {
    super.didUpdateWidget(old);
    final newVal = (widget.initialValue == 'N/A' || widget.initialValue == '-')
        ? ''
        : widget.initialValue;
    if (_ctrl.text != newVal && !FocusScope.of(context).hasFocus) {
      _ctrl.text = newVal;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarn = widget.isMissing && widget.isRequired;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: _ctrl,
        maxLength: widget.maxLen,
        maxLines: widget.maxLen > 60 ? 3 : 1,
        minLines: 1,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: widget.isRequired ? '${widget.label} *' : widget.label,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: isWarn
                ? Colors.amber.shade700
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isWarn ? FontWeight.w700 : FontWeight.w500,
          ),
          helperText: isWarn ? 'Missing value — tap to fill' : widget.aiHint,
          helperStyle: isWarn
              ? TextStyle(
                  color: Colors.amber.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )
              : null,
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusSm,
            borderSide: BorderSide(
              color: isWarn ? Colors.amber.shade600 : theme.colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusSm,
            borderSide: BorderSide(
              color: isWarn
                  ? Colors.amber.shade600
                  : theme.colorScheme.outline.withValues(alpha: 0.7),
              width: isWarn ? 1.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusSm,
            borderSide: BorderSide(
              color: isWarn ? Colors.amber.shade600 : theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: isWarn
              ? Colors.amber.withValues(alpha: 0.08)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
          suffixIcon: widget.isRewriting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  tooltip: 'AI Polish',
                  onPressed: widget.onRewrite,
                ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
