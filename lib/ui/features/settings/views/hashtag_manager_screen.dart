import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';

import '../view_models/settings_view_model.dart';
import 'widgets/add_hashtag_group_dialog.dart';

/// Hashtag group manager screen with serene cards and default tags.
class HashtagManagerScreen extends ConsumerWidget {
  const HashtagManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final groups = state.hashtagGroups;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hashtag Manager',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: groups.isEmpty
          ? EmptyState(
              icon: Icons.tag_rounded,
              title: 'No Hashtag Groups',
              description: 'Create hashtag groups to quickly append tags to your curated football posts.',
              actionLabel: 'Add Hashtag Group',
              onAction: () => AddHashtagGroupDialog.show(context),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.base,
                  ),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isDefault = group.isDefault;

                    return AppCard(
                      borderColor: isDefault ? theme.colorScheme.primary : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      group.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              AppSpacing.borderRadiusPill,
                                        ),
                                        child: Text(
                                          'DEFAULT',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  group.hashtags,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusSm,
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            onSelected: (value) async {
                              Haptics.selectionClick();
                              if (value == 'default') {
                                notifier.setDefaultHashtagGroup(group.id);
                              } else if (value == 'delete') {
                                final groups = ref
                                    .read(settingsViewModelProvider)
                                    .hashtagGroups;
                                final nextDefault = groups
                                    .where((g) => g.id != group.id)
                                    .firstOrNull
                                    ?.name;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete "${group.name}"?'),
                                    content: Text(
                                      group.isDefault && nextDefault != null
                                          ? 'Default will move to "$nextDefault".'
                                          : 'This hashtag group will be removed permanently.',
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
                                await notifier.removeHashtagGroup(group);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: const Text('Group deleted'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () =>
                                            notifier.addHashtagGroup(group),
                                      ),
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isDefault)
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Set as Default'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Haptics.lightImpact();
          AddHashtagGroupDialog.show(context);
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 1,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
