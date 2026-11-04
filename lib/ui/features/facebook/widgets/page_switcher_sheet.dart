import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';

/// Bottom sheet listing every connected Page. Switching changes the active
/// publish target; the composer owns the draft-mismatch guard.
class PageSwitcherSheet extends ConsumerWidget {
  const PageSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const PageSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connection = ref.watch(facebookViewModelProvider);
    final pages = connection.pages;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Post as',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (pages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.base,
                ),
                child: Text(
                  'No Page connected yet. Add one to start posting.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final page in pages)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: FacebookPageAvatar(
                    pageName: page.name,
                    pictureUrl: page.pictureUrl,
                    size: 40,
                  ),
                  title: Text(
                    page.name.isEmpty ? 'Facebook Page' : page.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: page.id == connection.activePageId
                      ? const Text('Active')
                      : null,
                  trailing: page.id == connection.activePageId
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  onTap: () async {
                    Haptics.selection();
                    await ref
                        .read(facebookViewModelProvider.notifier)
                        .switchPage(page.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle_outline_rounded),
              title: const Text('Add Page'),
              onTap: () {
                Navigator.of(context).pop();
                FacebookConnectionDialog.show(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Manage connection'),
              onTap: () {
                Navigator.of(context).pop();
                FacebookConnectionDialog.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact avatar + name used by the Page switcher header.
class ActivePageChip extends ConsumerWidget {
  const ActivePageChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(facebookViewModelProvider);
    return PageIdentityRow(
      pageName: connection.pageName,
      pagePictureUrl: connection.pagePictureUrl,
      needsConnection: !connection.isConnected,
      onTap: onTap,
    );
  }
}
