import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/settings_view_model.dart';
import 'widgets/add_hashtag_group_dialog.dart';

class HashtagManagerScreen extends StatelessWidget {
  const HashtagManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final groups = viewModel.hashtagGroups;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hashtag Manager'),
      ),
      body: groups.isEmpty
          ? Center(
              child: Text(
                'No hashtag groups added yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final isDefault = group.isDefault;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(
                      color: isDefault
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: isDefault ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        group.hashtags,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'default') {
                          viewModel.setDefaultHashtagGroup(group.id);
                        } else if (value == 'delete') {
                          viewModel.removeHashtagGroup(group);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Text('Set as Default'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddHashtagGroupDialog.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
