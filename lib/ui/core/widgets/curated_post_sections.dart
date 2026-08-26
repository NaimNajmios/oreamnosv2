import 'package:flutter/material.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/typewriter_markdown.dart';

class TitleBlock extends StatelessWidget {
  final String title;
  final bool visible;
  const TitleBlock({super.key, required this.title, this.visible = true});

  @override
  Widget build(BuildContext context) {
    if (!visible || title.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.3,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Divider(
          thickness: 1,
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        const SizedBox(height: AppSpacing.base),
      ],
    );
  }
}

class BodyBlock extends StatelessWidget {
  final String bodyMarkdown;
  const BodyBlock({super.key, required this.bodyMarkdown});

  @override
  Widget build(BuildContext context) {
    if (bodyMarkdown.isEmpty) return const SizedBox.shrink();
    return TypewriterMarkdown(data: bodyMarkdown);
  }
}

class HashtagChips extends StatelessWidget {
  final List<String> hashtags;
  final bool visible;
  const HashtagChips({super.key, required this.hashtags, this.visible = true});

  @override
  Widget build(BuildContext context) {
    if (!visible || hashtags.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: hashtags.map((h) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: AppSpacing.borderRadiusPill,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            '#$h',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
