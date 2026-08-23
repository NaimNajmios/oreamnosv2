import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'app_card.dart';

/// Container with swipe-to-copy (right) and swipe-to-share (left).
class SwipeableOutputCard extends StatelessWidget {
  const SwipeableOutputCard({
    super.key,
    required this.child,
    required this.content,
  });

  final Widget child;
  final String content;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    Haptics.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
      ),
    );
  }

  void _share(BuildContext context) {
    Haptics.mediumImpact();
    // ignore: deprecated_member_use
    Share.share(content);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey<String>(content.hashCode.toString()),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _copy(context);
        } else if (direction == DismissDirection.endToStart) {
          _share(context);
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: const Row(
          children: [
            Icon(Icons.copy_rounded, color: AppColors.success, size: 20),
            SizedBox(width: 8),
            Text(
              'Copy',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Share',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.share_rounded, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
