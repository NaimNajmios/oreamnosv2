import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/card_field.dart';
import 'package:oreamnos/domain/models/card_field_registry.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_mark.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

import 'studio_deck_lists.dart';

/// Studio Deck — bottom-sheet field editor for the sealed CardData model.
///
/// Generic over [CardFieldRegistry.fieldsFor]: renders every editable
/// (non-list, non-bool) field for the selected template with char counters,
/// MISSING amber chips + dashed borders for blank required fields, and
/// per-field AI polish via [CardGeneratorViewModel.rewriteDynamicField].
/// Template switching reuses cached extraction via [CardGeneratorViewModel.setTemplate].
class StudioDeckSheet extends ConsumerWidget {
  const StudioDeckSheet({super.key});

  static Future<void> show(BuildContext context) {
    Haptics.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const StudioDeckSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardGeneratorViewModelProvider);
    final notifier = ref.read(cardGeneratorViewModelProvider.notifier);
    final theme = Theme.of(context);
    final fields = CardFieldRegistry.fieldsFor(state.selectedTemplate);
    final json = state.cardData?.toJson() ?? const {};
    final editable = fields
        .where(
          (f) => f.type != CardFieldType.list && f.type != CardFieldType.bool_,
        )
        .toList();
    // Blank required fields count as missing even before AI extraction runs
    // (no brief / no API key yet) — blank slots hide on export either way.
    bool isBlank(String key) {
      final raw = json[key];
      final s = raw == null ? '' : raw.toString();
      final t = s.trim();
      return t.isEmpty || t == 'N/A' || t == '-';
    }

    final blankRequired = editable
        .where((f) => f.required && isBlank(f.key))
        .map((f) => f.key)
        .toSet();
    final missingCount = {...state.missingFields, ...blankRequired}.length;
    const groups = ['primary', 'secondary', 'optional'];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Studio Deck',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        missingCount == 0
                            ? 'All required fields filled'
                            : '$missingCount missing field${missingCount == 1 ? '' : 's'} — blank slots hide on export',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: missingCount == 0
                              ? theme.colorScheme.primary
                              : Colors.amber.shade700,
                          fontWeight: missingCount == 0
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (missingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.amber.shade600),
                    ),
                    child: Text(
                      '$missingCount MISSING',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Center(child: KickoffDotsDivider()),
          ),
          // Template switcher (cached re-extraction via setTemplate).
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: CardTemplate.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = CardTemplate.all[i];
                final selected = t == state.selectedTemplate;
                return ChoiceChip(
                  label: Text(t.displayName),
                  selected: selected,
                  onSelected: (_) {
                    if (!selected) {
                      Haptics.selectionClick();
                      notifier.setTemplate(t);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                FilledButton.tonalIcon(
                  onPressed: state.isExtracting
                      ? null
                      : () => notifier.regenerateAllFields(),
                  icon: state.isExtracting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    state.isExtracting ? 'Regenerating…' : 'AI Rewrite All',
                  ),
                ),
                const SizedBox(height: 12),
                for (final group in groups)
                  if (editable.any((f) => f.group == group)) ...[
                    _GroupHeader(label: group),
                    for (final field in editable.where((f) => f.group == group))
                      _DeckField(
                        field: field,
                        initialValue: () {
                          final raw = json[field.key];
                          final s = raw == null ? '' : raw.toString();
                          return (s == 'N/A' || s == '-') ? '' : s;
                        }(),
                        isMissing:
                            state.missingFields.contains(field.key) ||
                            (field.required && isBlank(field.key)),
                        isRewriting: state.isRewriting(field.key),
                        onChanged: (v) =>
                            notifier.updateCardField(field.key, v),
                        onRewrite: () async {
                          final brief = state.brief;
                          if (brief == null) return;
                          final apiKey = await getIt<PreferencesService>()
                              .getApiKey(brief.provider);
                          if (apiKey == null || apiKey.isEmpty) return;
                          Haptics.lightImpact();
                          await notifier.rewriteDynamicField(
                            fieldKey: field.key,
                            provider: brief.provider,
                            modelId: brief.modelId,
                            apiKey: apiKey,
                          );
                        },
                      ),
                  ],
                for (final field in fields.where(
                  (f) => f.type == CardFieldType.list,
                ))
                  DeckListSection(
                    key: ValueKey(
                      'decklist_${state.selectedTemplate.name}_${field.key}',
                    ),
                    template: state.selectedTemplate,
                    field: field,
                  ),
                for (final field in fields.where(
                  (f) => f.type == CardFieldType.bool_,
                ))
                  SwitchListTile(
                    title: Text(field.label),
                    subtitle: field.aiHint != null ? Text(field.aiHint!) : null,
                    value:
                        (json[field.key] as bool?) ??
                        (json[field.key].toString().toLowerCase() == 'true'),
                    onChanged: (v) => notifier.setCardBoolField(field.key, v),
                    contentPadding: EdgeInsets.zero,
                  ),
                if (state.rewriteError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.rewriteError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckField extends StatefulWidget {
  const _DeckField({
    required this.field,
    required this.initialValue,
    required this.isMissing,
    required this.isRewriting,
    required this.onChanged,
    required this.onRewrite,
  });

  final CardFieldDescriptor field;
  final String initialValue;
  final bool isMissing;
  final bool isRewriting;
  final ValueChanged<String> onChanged;
  final VoidCallback onRewrite;

  @override
  State<_DeckField> createState() => _DeckFieldState();
}

class _DeckFieldState extends State<_DeckField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_DeckField old) {
    super.didUpdateWidget(old);
    if (old.initialValue != widget.initialValue &&
        !FocusScope.of(context).hasFocus) {
      _ctrl.text = widget.initialValue;
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
    final isWarn = widget.isMissing && widget.field.required;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.field.required
                      ? '${widget.field.label} *'
                      : widget.field.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isWarn
                        ? Colors.amber.shade800
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isWarn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.amber.shade600,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    'MISSING',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            maxLength: widget.field.maxChars > 0 ? widget.field.maxChars : 120,
            maxLines: widget.field.maxChars > 60 ? 3 : 1,
            minLines: 1,
            decoration: InputDecoration(
              hintText: widget.field.aiHint ?? 'Tap to fill',
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: isWarn
                  ? Colors.amber.withValues(alpha: 0.08)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
                borderSide: BorderSide(
                  color: isWarn
                      ? Colors.amber.shade600
                      : theme.colorScheme.outline,
                  style: isWarn ? BorderStyle.solid : BorderStyle.solid,
                  width: isWarn ? 1.5 : 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
                borderSide: BorderSide(
                  color: isWarn
                      ? Colors.amber.shade600
                      : theme.colorScheme.outline.withValues(alpha: 0.7),
                  width: isWarn ? 1.5 : 1.0,
                ),
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
        ],
      ),
    );
  }
}
