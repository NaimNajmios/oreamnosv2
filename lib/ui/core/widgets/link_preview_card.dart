import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/config/theme/app_typography.dart';

import 'app_button.dart';
import 'app_card.dart';

class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({
    super.key,
    required this.url,
    this.title,
    this.description,
    this.onExtract,
    this.isLoading = false,
  });

  final String url;
  final String? title;
  final String? description;
  final VoidCallback? onExtract;
  final bool isLoading;

  String _getDomain(String urlStr) {
    try {
      final uri = Uri.parse(urlStr);
      return uri.host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return urlStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final domain = _getDomain(url);
    final domainInitial = domain.isNotEmpty ? domain[0].toUpperCase() : '🔗';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      accentColor: isDark ? AppColors.darkTeal : AppColors.lightTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkTeal : AppColors.lightTeal)
                      .withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  domainInitial,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTeal : AppColors.lightTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      url,
                      style: AppTypography.mono(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onExtract != null) ...[
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Extract',
                  icon: Icons.auto_awesome_rounded,
                  height: 32,
                  isLoading: isLoading,
                  onPressed: onExtract,
                ),
              ],
            ],
          ),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
