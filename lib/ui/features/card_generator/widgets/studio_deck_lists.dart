import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/card_field.dart';
import 'package:oreamnos/domain/models/card_template.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

/// Sub-field spec for a Deck list row.
class DeckSubField {
  const DeckSubField(
    this.key,
    this.label, {
    this.numeric = false,
    this.maxChars = 30,
  });
  final String key;
  final String label;
  final bool numeric;
  final int maxChars;
}

/// Row schema per (template, list key). Mirrors the nested Freezed types
/// (StatItem, ComparisonStat, LineupPlayer, TableRow, InjuryItem,
/// ContractPlayer, NomineeItem).
List<DeckSubField> deckListSchema(CardTemplate template, String key) {
  if (template == CardTemplate.matchStatsComparison && key == 'stats') {
    return const [
      DeckSubField('label', 'Label', maxChars: 20),
      DeckSubField('homeValue', 'Home', maxChars: 12),
      DeckSubField('awayValue', 'Away', maxChars: 12),
    ];
  }
  if (key == 'starters' || key == 'subs') {
    return const [
      DeckSubField('number', 'No.', numeric: true, maxChars: 3),
      DeckSubField('name', 'Player name', maxChars: 25),
    ];
  }
  if (key == 'standings') {
    return const [
      DeckSubField('position', '#', numeric: true, maxChars: 3),
      DeckSubField('teamName', 'Team', maxChars: 20),
      DeckSubField('played', 'P', numeric: true, maxChars: 3),
      DeckSubField('points', 'Pts', numeric: true, maxChars: 3),
    ];
  }
  if (key == 'injuries' || key == 'doubtfits' || key == 'returns') {
    return const [
      DeckSubField('playerName', 'Player', maxChars: 25),
      DeckSubField('injury', 'Injury', maxChars: 25),
      DeckSubField('status', 'Status', maxChars: 15),
    ];
  }
  if (key == 'expiringPlayers' || key == 'renewals') {
    return const [
      DeckSubField('playerName', 'Player', maxChars: 25),
      DeckSubField('position', 'Pos', maxChars: 12),
      DeckSubField('expiresIn', 'Expires', maxChars: 15),
    ];
  }
  if (key == 'nominees') {
    return const [
      DeckSubField('playerName', 'Nominee', maxChars: 25),
      DeckSubField('club', 'Club', maxChars: 20),
      DeckSubField('achievement', 'Achievement', maxChars: 40),
    ];
  }
  // StatItem default (topStats, rivalry, onThisDay keyStats).
  return const [
    DeckSubField('label', 'Label', maxChars: 25),
    DeckSubField('value', 'Value', maxChars: 12),
    DeckSubField('context', 'Context', maxChars: 30),
  ];
}

Map<String, String> deckEmptyRow(List<DeckSubField> schema) => {
  for (final s in schema) s.key: '',
};

int deckRowCap(String key) => switch (key) {
  'starters' => 11,
  'subs' => 7,
  'standings' => 5,
  _ => 8,
};

/// Editable list section for Deck (lineups, stats, standings, injuries,
/// nominees). Rows round-trip through
/// [CardGeneratorViewModel.updateCardListField] with number coercion.
class DeckListSection extends ConsumerStatefulWidget {
  const DeckListSection({
    super.key,
    required this.template,
    required this.field,
  });

  final CardTemplate template;
  final CardFieldDescriptor field;

  @override
  ConsumerState<DeckListSection> createState() => _DeckListSectionState();
}

class _DeckListSectionState extends ConsumerState<DeckListSection> {
  late List<DeckSubField> _schema;
  late List<Map<String, String>> _rows;
  String _loadedFor = '';

  @override
  void initState() {
    super.initState();
    _schema = deckListSchema(widget.template, widget.field.key);
    _rows = [];
  }

  void _syncFromState(CardGeneratorStateSnapshot snap) {
    final tag = '${snap.runtimeType}#${snap.revision}';
    if (tag == _loadedFor) return;
    _loadedFor = tag;
    _rows = snap.rows
        .map(
          (r) => {for (final s in _schema) s.key: (r[s.key]?.toString() ?? '')},
        )
        .toList();
  }

  void _push() {
    ref.read(cardGeneratorViewModelProvider.notifier).updateCardListField(
      widget.field.key,
      [for (final r in _rows) Map<String, dynamic>.from(r)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardState = ref.watch(cardGeneratorViewModelProvider);
    final raw = cardState.cardData?.toJson()[widget.field.key];
    final snap = CardGeneratorStateSnapshot(
      cardKind: cardState.cardData.runtimeType.toString(),
      revision: cardState.undoStack.length,
      rows: raw is List
          ? [
              for (final e in raw)
                e is Map
                    ? Map<String, dynamic>.from(e)
                    : <String, dynamic>{'value': e.toString()},
            ]
          : const [],
    );
    _syncFromState(snap);

    final cap = deckRowCap(widget.field.key);
    final isMissing =
        widget.field.required &&
        _rows.every((r) => r.values.every((v) => v.trim().isEmpty));

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
                    color: isMissing
                        ? Colors.amber.shade800
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isMissing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.amber.shade600),
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
              Text(
                '${_rows.length}/$cap',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          if (widget.field.aiHint != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.field.aiHint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < _rows.length; i++)
            _DeckListRow(
              key: ValueKey('${widget.field.key}_$i'),
              index: i,
              row: _rows[i],
              schema: _schema,
              onChanged: (subKey, value) {
                _rows[i][subKey] = value;
                _push();
              },
              onDelete: () {
                setState(() => _rows.removeAt(i));
                _push();
              },
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add row (${_rows.length}/$cap)'),
            onPressed: _rows.length >= cap
                ? null
                : () {
                    setState(() => _rows.add(deckEmptyRow(_schema)));
                    _push();
                  },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight snapshot tag so the section reloads rows when the card or
/// undo stack changes (template switch / undo / redo / rewrite).
class CardGeneratorStateSnapshot {
  const CardGeneratorStateSnapshot({
    required this.cardKind,
    required this.revision,
    required this.rows,
  });
  final String cardKind;
  final int revision;
  final List<Map<String, dynamic>> rows;
}

class _DeckListRow extends StatelessWidget {
  const _DeckListRow({
    super.key,
    required this.index,
    required this.row,
    required this.schema,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final Map<String, String> row;
  final List<DeckSubField> schema;
  final void Function(String subKey, String value) onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '#${index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                tooltip: 'Delete row',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
          for (final s in schema) ...[
            const SizedBox(height: 6),
            TextFormField(
              key: ValueKey('cell_${index}_${s.key}'),
              initialValue: row[s.key] ?? '',
              maxLength: s.maxChars,
              keyboardType: s.numeric
                  ? const TextInputType.numberWithOptions(signed: true)
                  : TextInputType.text,
              inputFormatters: s.numeric
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))]
                  : null,
              decoration: InputDecoration(
                labelText: s.label,
                counterText: '',
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => onChanged(s.key, v),
            ),
          ],
        ],
      ),
    );
  }
}
