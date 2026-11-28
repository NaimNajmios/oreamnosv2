import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/domain/models/research_context.dart';
import 'package:oreamnos/domain/services/enrich_context_usecase.dart';
import 'package:oreamnos/domain/services/intent_classifier.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Redacted view of web-research runs: which query was sent, which results
/// passed the relevance guard, and why the rest were dropped.
///
/// No API keys, snippets, or response bodies are stored or displayed.
class SearchDiagnosticsScreen extends ConsumerStatefulWidget {
  const SearchDiagnosticsScreen({super.key});

  @override
  ConsumerState<SearchDiagnosticsScreen> createState() =>
      _SearchDiagnosticsScreenState();
}

class _SearchDiagnosticsScreenState
    extends ConsumerState<SearchDiagnosticsScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _lastMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runQuery(String query) async {
    final text = query.trim();
    if (text.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _lastMessage = null;
    });
    try {
      final result = await getIt<EnrichContextUseCase>().execute(
        text,
        InputIntent.shortQuery,
      );
      if (!mounted) return;
      setState(
        () => _lastMessage = '${result.status.name}: ${result.message ?? ''}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastMessage = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copySummary() async {
    final summary = getIt<SearchDiagnosticsRecorder>().buildSummary();
    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redacted diagnostics copied.')),
    );
  }

  void _clear() {
    getIt<SearchDiagnosticsRecorder>().clear();
    if (!mounted) return;
    setState(() => _lastMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsViewModelProvider);
    final service = getIt<SearchDiagnosticsRecorder>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Web search diagnostics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy redacted summary',
            onPressed: _copySummary,
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Clear history',
            onPressed: _clear,
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
          ),
        ],
      ),
      body: StreamBuilder<List<SearchDiagnosticEntry>>(
        stream: service.stream,
        initialData: service.snapshot,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <SearchDiagnosticEntry>[];
          return ListView(
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
                  _Row(
                    'Tavily key',
                    (settings.tavilyApiKey?.isNotEmpty ?? false)
                        ? 'Configured'
                        : 'Not set',
                  ),
                  _Row('Runs recorded', '${entries.length}'),
                  _Row(
                    'Last status',
                    entries.isEmpty ? '—' : entries.last.status.name,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Try a query',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Paste a headline or a short query',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _runQuery(_controller.text),
                        icon: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Run'),
                      ),
                    ),
                    if (_lastMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _lastMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Recent runs',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (entries.isEmpty)
                AppCard(
                  child: Text(
                    'No research runs yet. Enable Web research on the Generate '
                    'tab, or run a query above.',
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
                      for (var i = 0; i < entries.length; i++)
                        _EntryRow(
                          entry: entries[entries.length - 1 - i],
                          showDivider: i != entries.length - 1,
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
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

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.showDivider});

  final SearchDiagnosticEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = entry.status == ResearchStatus.failed;
    final time =
        '${entry.at.hour.toString().padLeft(2, '0')}:'
        '${entry.at.minute.toString().padLeft(2, '0')}';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : Icons.travel_explore_rounded,
                    size: 15,
                    color: failed
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$time · ${entry.status.name}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.keptCount}/${entry.resultCount} kept · '
                    '${entry.credits} cr',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (entry.query.isNotEmpty)
                Text(entry.query, style: theme.textTheme.bodySmall),
              Text(
                [
                  'planner=${entry.planner}',
                  if (entry.intent.isNotEmpty) 'intent=${entry.intent}',
                  if (entry.topic.isNotEmpty) 'topic=${entry.topic}',
                  if (entry.requestId != null) 'request=${entry.requestId}',
                  if (entry.message != null) entry.message!,
                  if (entry.failureKind != null) 'failure=${entry.failureKind}',
                ].join(' · '),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final decision in entry.decisions.take(6))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${decision.keep ? 'KEEP' : 'DROP'} '
                    '${decision.score.toStringAsFixed(2)} '
                    '${decision.reason}: ${decision.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: decision.keep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
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
