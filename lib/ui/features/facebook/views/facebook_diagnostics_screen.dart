import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_diagnostics.dart';
import 'package:oreamnos/data/services/log_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

/// Redacted connection, sync, and event history for the Facebook module.
///
/// Tokens, captions, URLs, and response bodies are never shown: only the
/// failure taxonomy and timestamps recorded by [FacebookDiagnostics].
class FacebookDiagnosticsScreen extends ConsumerStatefulWidget {
  const FacebookDiagnosticsScreen({super.key});

  @override
  ConsumerState<FacebookDiagnosticsScreen> createState() =>
      _FacebookDiagnosticsScreenState();
}

class _FacebookDiagnosticsScreenState
    extends ConsumerState<FacebookDiagnosticsScreen> {
  DateTime? _lastReconcile;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _lastReconcile = getIt<PreferencesService>().lastFacebookReconcile;
  }

  Future<void> _runHealthCheck() async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptics.lightImpact();
    await ref
        .read(facebookViewModelProvider.notifier)
        .checkConnectionHealth(force: true);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reconcileNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptics.lightImpact();
    await ref
        .read(facebookDraftProvider.notifier)
        .reconcileScheduled(force: true);
    final prefs = getIt<PreferencesService>();
    if (mounted) {
      setState(() {
        _lastReconcile = prefs.lastFacebookReconcile;
        _busy = false;
      });
    }
  }

  Future<void> _copySummary(
    FacebookUiState connection,
    List<FacebookPostRecord> records,
    List<LogEntry> logs,
  ) async {
    final summary = buildFacebookDiagnosticsSummary(
      connection: connection,
      lastReconcile: _lastReconcile,
      scheduledCount: records.where((r) => r.isScheduled).length,
      scheduledSyncFailed: ref.read(facebookDraftProvider).scheduledSyncFailed,
      logs: logs,
    );
    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redacted diagnostics copied.')),
    );
  }

  void _clearFacebookLogs() {
    ref.read(logNotifierProvider.notifier).clearTag(FacebookDiagnostics.tag);
    Haptics.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connection = ref.watch(facebookViewModelProvider);
    final draft = ref.watch(facebookDraftProvider);
    final records = ref.watch(facebookHistoryProvider);
    final logs = ref
        .watch(logNotifierProvider)
        .where((entry) => entry.tag == FacebookDiagnostics.tag)
        .toList()
        .reversed
        .take(20)
        .toList(growable: false);
    final scheduledCount = records.where((r) => r.isScheduled).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connection diagnostics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy diagnostics',
            onPressed: () => _copySummary(connection, records, logs),
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.base,
          AppSpacing.base,
          AppSpacing.xxl,
        ),
        children: [
          _Section(
            title: 'Connection',
            rows: [
              _Row('Status', connection.status.name),
              _Row(
                'Page',
                connection.pageName.isEmpty ? '—' : connection.pageName,
              ),
              _Row(
                'Page id',
                connection.pageId.isEmpty ? '—' : connection.pageId,
              ),
              _Row('Offline', connection.offline ? 'Yes' : 'No'),
              _Row('Expired', connection.isExpired ? 'Yes' : 'No'),
              _Row(
                'Last health check',
                _formatTime(connection.lastHealthCheckAt),
              ),
              _Row('Last health error', connection.lastHealthErrorKind ?? '—'),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _Section(
            title: 'Scheduled sync',
            rows: [
              _Row('Last reconcile', _formatTime(_lastReconcile)),
              _Row('Scheduled posts', '$scheduledCount'),
              _Row(
                'Last sync failed',
                draft.scheduledSyncFailed ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _runHealthCheck,
                icon: const Icon(Icons.health_and_safety_outlined, size: 18),
                label: const Text('Run health check'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _reconcileNow,
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Reconcile now'),
              ),
              TextButton.icon(
                onPressed: logs.isEmpty ? null : _clearFacebookLogs,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Clear Facebook logs'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recent events',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (logs.isEmpty)
            AppCard(
              child: Text(
                'No Facebook events recorded yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < logs.length; i++)
                    _LogRow(entry: logs[i], showDivider: i != logs.length - 1),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i != 0) const Divider(height: AppSpacing.base),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.showDivider});

  final LogEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = entry.logLevel == LogLevel.error;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                failed
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: failed
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.details != null && entry.details!.isNotEmpty)
                      Text(
                        entry.details!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      entry.formattedDate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: theme.dividerColor),
      ],
    );
  }
}

/// Plain-text summary copied to the clipboard. Contains no secrets.
String buildFacebookDiagnosticsSummary({
  required FacebookUiState connection,
  required DateTime? lastReconcile,
  required int scheduledCount,
  required bool scheduledSyncFailed,
  required List<LogEntry> logs,
}) {
  final buffer = StringBuffer()
    ..writeln('Facebook diagnostics')
    ..writeln('status=${connection.status.name}')
    ..writeln('page=${connection.pageName}')
    ..writeln('pageId=${connection.pageId}')
    ..writeln('offline=${connection.offline}')
    ..writeln('expired=${connection.isExpired}')
    ..writeln('lastHealthCheck=${_formatTime(connection.lastHealthCheckAt)}')
    ..writeln('lastHealthError=${connection.lastHealthErrorKind ?? 'none'}')
    ..writeln('lastReconcile=${_formatTime(lastReconcile)}')
    ..writeln('scheduledCount=$scheduledCount')
    ..writeln('scheduledSyncFailed=$scheduledSyncFailed')
    ..writeln('events=${logs.length}');
  for (final entry in logs) {
    buffer.writeln(
      '${entry.formattedDate} ${entry.level} ${entry.message} '
      '${entry.details ?? ''}',
    );
  }
  return buffer.toString().trimRight();
}

String _formatTime(DateTime? at) {
  if (at == null) return '—';
  final h = at.hour.toString().padLeft(2, '0');
  final m = at.minute.toString().padLeft(2, '0');
  return '${at.year}-${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')} $h:$m';
}
