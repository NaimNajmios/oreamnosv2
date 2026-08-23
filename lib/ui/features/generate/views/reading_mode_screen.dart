import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/typewriter_markdown.dart';

/// Full-screen distraction-free reading mode with editorial type ramp.
class ReadingModeScreen extends StatelessWidget {
  const ReadingModeScreen({
    super.key,
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Centered Reading Column
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.huge + AppSpacing.base,
                    AppSpacing.xl,
                    100, // Space for bottom action bar
                  ),
                  child: TypewriterMarkdown(
                    data: content,
                  ),
                ),
              ),
            ),

            // Top Floating Close Button
            Positioned(
              top: AppSpacing.base,
              right: AppSpacing.base,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Haptics.lightImpact();
                    context.pop();
                  },
                  borderRadius: AppSpacing.borderRadiusPill,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.outline, width: 1),
                      boxShadow: AppSpacing.softShadow,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Floating Actions (Copy & Share)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.xl,
              child: Center(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  borderRadius: AppSpacing.borderRadiusPill,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: content));
                          Haptics.mediumImpact();
                          if (context.mounted) {
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
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.content_copy_rounded, size: 18),
                        label: const Text('Copy'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: theme.colorScheme.outline,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Haptics.lightImpact();
                          // ignore: deprecated_member_use
                          Share.share(content);
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
