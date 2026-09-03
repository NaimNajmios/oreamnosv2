import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

/// Central floating snackbar helper: consistent shape, motion, and haptics.
///
/// Use for undoable deletes and lightweight confirmations. Persistent
/// inline errors (not snackbars) remain the pattern for failures.
abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Haptics.warning();
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
      ),
    );
  }

  static void showUndone(BuildContext context, String message) {
    Haptics.warning();
    show(context, message, icon: Icons.undo_rounded);
  }

  static void showSuccess(BuildContext context, String message) {
    Haptics.success();
    show(
      context,
      message,
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    Haptics.error();
    show(
      context,
      message,
      icon: Icons.error_outline_rounded,
      duration: const Duration(seconds: 3),
    );
  }
}
