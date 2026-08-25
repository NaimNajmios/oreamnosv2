import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/config/theme/app_typography.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';

class LogDetailsDialog extends StatelessWidget {
  const LogDetailsDialog({super.key, required this.entry});
  final LogEntry entry;

  Color _levelColor(BuildContext context) {
    switch (entry.level) {
      case 'ERROR':
        return AppColors.error;
      case 'WARN':
      case 'WARNING':
        return AppColors.warning;
      case 'DEBUG':
        return const Color(0xFF9E9E9E);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _levelColor(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg, side: BorderSide(color: theme.colorScheme.outline)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppSpacing.borderRadiusXs),
            child: Text(entry.level, style: AppTypography.mono(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(entry.tag, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.formattedDate, style: AppTypography.mono(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            SelectableText(entry.message, style: AppTypography.mono(fontSize: 12, color: theme.colorScheme.onSurface)),
            if (entry.details != null) ...[
              const SizedBox(height: 8),
              SelectableText(entry.details!, style: AppTypography.mono(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
            if (entry.error != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: AppSpacing.borderRadiusXs),
                child: SelectableText(entry.error!, style: AppTypography.mono(fontSize: 11, color: AppColors.error)),
              ),
            ],
            if (entry.error == null && entry.details == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No additional details.', style: AppTypography.mono(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)).copyWith(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        FilledButton(
          onPressed: () async {
            final buf = StringBuffer();
            buf.writeln('Level: ${entry.level}');
            buf.writeln('Time: ${entry.formattedDate}');
            buf.writeln('Tag: ${entry.tag}');
            buf.writeln('Message: ${entry.message}');
            if (entry.details != null) buf.writeln('Details: ${entry.details}');
            if (entry.error != null) buf.writeln('Error: ${entry.error}');
            await Clipboard.setData(ClipboardData(text: buf.toString()));
            Haptics.mediumImpact();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Copy'),
        ),
      ],
    );
  }
}
