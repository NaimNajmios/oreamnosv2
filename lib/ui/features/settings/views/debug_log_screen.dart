import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../data/services/log_service.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';

/// Internal system debug log viewer with monospace typography and semantic badges.
class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final LogService _logService = LogService();
  final _dateFormat = DateFormat('HH:mm:ss.SSS');

  @override
  void initState() {
    super.initState();
    _logService.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    _logService.removeListener(_onLogsChanged);
    super.dispose();
  }

  void _onLogsChanged() {
    setState(() {});
  }

  Future<void> _copyLogs() async {
    final logs = _logService.logs;
    if (logs.isEmpty) return;

    final buffer = StringBuffer();
    for (var log in logs) {
      buffer.writeln('[${_dateFormat.format(log.timestamp)}] [${log.level}] ${log.message}');
      if (log.error != null) {
        buffer.writeln(log.error);
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    Haptics.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Logs copied to clipboard'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
        ),
      );
    }
  }

  Color _getLevelColor(String level, ThemeData theme) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return AppColors.error;
      case 'WARN':
      case 'WARNING':
        return AppColors.warning;
      case 'INFO':
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = _logService.logs.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Logs',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (logs.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear logs',
              onPressed: () {
                Haptics.heavyImpact();
                _logService.clear();
              },
            ),
            IconButton(
              icon: const Icon(Icons.content_copy_rounded),
              tooltip: 'Copy all',
              onPressed: _copyLogs,
            ),
          ],
        ],
      ),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.bug_report_outlined,
              title: 'No Logs Recorded',
              description: 'System lifecycle events, scraping results, and API errors will appear here.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.base,
                  ),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final color = _getLevelColor(log.level, theme);

                    return AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: AppSpacing.borderRadiusXs,
                                ),
                                child: Text(
                                  log.level,
                                  style: AppTypography.mono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _dateFormat.format(log.timestamp),
                                style: AppTypography.mono(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SelectableText(
                            log.message,
                            style: AppTypography.mono(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (log.error != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: AppSpacing.borderRadiusXs,
                              ),
                              child: SelectableText(
                                log.error!,
                                style: AppTypography.mono(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
