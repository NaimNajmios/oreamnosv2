import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';

import '../view_models/settings_view_model.dart';
import 'widgets/add_pill_dialog.dart';

/// Custom refinement pills manager screen with serene cards.
class PillManagerScreen extends ConsumerWidget {
  const PillManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final pills = state.customPills;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Custom Refinement Pills',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: pills.isEmpty
          ? EmptyState(
              icon: Icons.edit_note_rounded,
              title: 'No Custom Pills',
              description: 'Create custom refinement pills with quick prompt instructions for your generated posts.',
              actionLabel: 'Add Custom Pill',
              onAction: () => AddPillDialog.show(context),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.base,
                  ),
                  itemCount: pills.length,
                  onReorderItem: (oldIndex, newIndex) {
                    Haptics.selectionClick();
                    notifier.reorderCustomPills(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final pill = pills[index];

                    return Padding(
                      key: ValueKey(pill.id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        onTap: () =>
                            AddPillDialog.show(context, existingPill: pill),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: AppSpacing.borderRadiusSm,
                              ),
                              child: Icon(
                                Icons.auto_fix_high_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pill.label,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pill.instruction,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              tooltip: 'Delete Pill',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete "${pill.label}"?'),
                                    content: const Text(
                                      'This custom pill will be removed permanently.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              theme.colorScheme.error,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                Haptics.heavyImpact();
                                await notifier.removeCustomPill(pill);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: const Text('Pill deleted'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () =>
                                            notifier.addCustomPill(pill),
                                      ),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                  right: AppSpacing.xs,
                                ),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: theme.colorScheme.outline,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Haptics.lightImpact();
          AddPillDialog.show(context);
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 1,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
