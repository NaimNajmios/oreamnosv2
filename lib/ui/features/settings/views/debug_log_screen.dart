import 'package:oreamnos/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_typography.dart';
import '../../../../data/services/log_service.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import 'widgets/log_details_dialog.dart';

/// Internal system debug log viewer with monospace typography and semantic badges.
class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final LogService _logService = getIt<LogService>();
  String _selectedLevel = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logService.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    _logService.removeListener(_onLogsChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _copyLogs() async {
    final logs = _logService.logs;
    if (logs.isEmpty) return;

    final buffer = StringBuffer();
    for (var log in logs) {
      buffer.writeln(
        '[${log.formattedTime}] [${log.level}] [${log.tag}] ${log.message}',
      );
      if (log.details != null) buffer.writeln('Details: ${log.details}');
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
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
      );
    }
  }

  Future<void> _confirmClear() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text(
          'Are you sure you want to clear all logs? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (result == true) {
      Haptics.heavyImpact();
      _logService.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logs cleared'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
        );
      }
    }
  }

  void _showDetails(LogEntry log) {
    showDialog(
      context: context,
      builder: (_) => LogDetailsDialog(entry: log),
    );
  }

  Color _getLevelColor(String level, ThemeData theme) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return AppColors.error;
      case 'WARN':
      case 'WARNING':
        return const Color(0xFFFBBC05);
      case 'DEBUG':
        return const Color(0xFF9E9E9E);
      case 'INFO':
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allLogs = _logService.logs.reversed.toList();
    final query = _searchQuery.trim().toLowerCase();

    final filteredLogs = allLogs.where((l) {
      if (_selectedLevel != 'ALL' && l.level.toUpperCase() != _selectedLevel) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchMsg = l.message.toLowerCase().contains(query);
        final matchTag = l.tag.toLowerCase().contains(query);
        final matchDetails = l.details?.toLowerCase().contains(query) ?? false;
        final matchError = l.error?.toLowerCase().contains(query) ?? false;
        return matchMsg || matchTag || matchDetails || matchError;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Logs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (allLogs.isNotEmpty)
              Text(
                '${filteredLogs.length} of ${allLogs.length} entries',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        actions: [
          if (allLogs.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear logs',
              onPressed: _confirmClear,
            ),
            IconButton(
              icon: const Icon(Icons.content_copy_rounded),
              tooltip: 'Copy all',
              onPressed: _copyLogs,
            ),
          ],
        ],
      ),
      body: allLogs.isEmpty
          ? const EmptyState(
              icon: Icons.bug_report_outlined,
              title: 'No Logs Recorded',
              description: 'System lifecycle events, scraping results, and API errors will appear here.',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: Column(
                  children: [
                    // Search & Filter controls
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.sm,
                        AppSpacing.screenHorizontal,
                        AppSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            style: theme.textTheme.bodySmall,
                            decoration: InputDecoration(
                              hintText: 'Search logs, tags, or errors...',
                              hintStyle: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                              ),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: AppSpacing.borderRadiusSm,
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final level in [
                                  'ALL',
                                  'INFO',
                                  'WARN',
                                  'ERROR',
                                  'DEBUG',
                                ]) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: FilterChip(
                                      label: Text(level),
                                      selected: _selectedLevel == level,
                                      showCheckmark: false,
                                      labelStyle: AppTypography.mono(
                                        fontSize: 10,
                                        fontWeight: _selectedLevel == level
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _selectedLevel == level
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.8),
                                      ),
                                      selectedColor: level == 'ERROR'
                                          ? AppColors.error
                                          : (level == 'WARN'
                                                ? const Color(0xFFFBBC05)
                                                : (level == 'DEBUG'
                                                      ? const Color(0xFF9E9E9E)
                                                      : theme
                                                            .colorScheme
                                                            .primary)),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onSelected: (_) {
                                        Haptics.selectionClick();
                                        setState(() => _selectedLevel = level);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filteredLogs.isEmpty
                          ? Center(
                              child: Text(
                                'No matching logs found.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenHorizontal,
                                vertical: AppSpacing.base,
                              ),
                              itemCount: filteredLogs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final log = filteredLogs[index];
                                final color = _getLevelColor(log.level, theme);

                                return InkWell(
                                  onTap: () => _showDetails(log),
                                  borderRadius: AppSpacing.borderRadiusMd,
                                  child: AppCard(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    AppSpacing.borderRadiusXs,
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
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              log.tag,
                                              style: AppTypography.mono(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Text(
                                              log.formattedTime,
                                              style: AppTypography.mono(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
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
                                            padding: const EdgeInsets.all(
                                              AppSpacing.sm,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(
                                                alpha: 0.08,
                                              ),
                                              borderRadius:
                                                  AppSpacing.borderRadiusXs,
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
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
