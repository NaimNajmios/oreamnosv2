import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_history_service.dart';
import 'package:oreamnos/data/services/facebook_reminder_service.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/widgets/empty_state.dart';
import 'package:oreamnos/ui/features/facebook/utils/facebook_external_links.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_calendar_view_model.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_calendar_month.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_post_actions_sheet.dart';

/// Month view of scheduled and published posts. Tap a day to inspect it and
/// reschedule or cancel; long-press a scheduled day to drag it to another.
class FacebookCalendarScreen extends ConsumerStatefulWidget {
  const FacebookCalendarScreen({super.key});

  @override
  ConsumerState<FacebookCalendarScreen> createState() =>
      _FacebookCalendarScreenState();
}

class _FacebookCalendarScreenState
    extends ConsumerState<FacebookCalendarScreen> {
  late DateTime _month;
  DateTime? _selectedDay;
  bool? _remindersEnabled;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = facebookCalendarDayKey(now);
    try {
      _remindersEnabled = getIt<FacebookReminderService>().enabled;
    } catch (_) {
      _remindersEnabled = null;
    }
  }

  Future<void> _toggleReminders(bool value) async {
    try {
      final service = getIt<FacebookReminderService>();
      await service.setEnabled(value);
      if (value) {
        await service.sync(ref.read(facebookHistoryProvider));
      }
      if (!mounted) return;
      setState(() => _remindersEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Reminders on' : 'Reminders off')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update reminders")),
      );
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _reschedule(FacebookPostRecord record, DateTime day) async {
    final connection = ref.read(facebookViewModelProvider);
    if (record.pageId.isNotEmpty && record.pageId != connection.activePageId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switch to that Page before rescheduling.'),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final initial = record.scheduledAt ?? now.add(const Duration(hours: 1));
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'New time',
    );
    if (time == null || !mounted) return;
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    final error = await ref
        .read(facebookDraftProvider.notifier)
        .reschedulePost(record.postId, at);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Post rescheduled')));
  }

  Future<void> _cancel(FacebookPostRecord record) async {
    final connection = ref.read(facebookViewModelProvider);
    if (record.pageId.isNotEmpty && record.pageId != connection.activePageId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to that Page before cancelling.')),
      );
      return;
    }
    final error = await ref
        .read(facebookDraftProvider.notifier)
        .cancelScheduledPost(record.postId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Scheduled post cancelled')),
    );
  }

  Future<void> _showDay(DateTime day) async {
    final records =
        ref.read(facebookCalendarProvider)[day] ?? const <FacebookPostRecord>[];
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${day.day} ${_monthName(day.month)} ${day.year}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                records.isEmpty
                    ? 'Nothing scheduled or published on this day.'
                    : '${records.length} '
                          '${records.length == 1 ? 'post' : 'posts'}',
              ),
            ),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.base),
                child: Icon(Icons.event_available_rounded, size: 32),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final record in records)
                    ListTile(
                      leading: Icon(
                        record.isScheduled
                            ? Icons.schedule_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      title: Text(
                        record.snippet.isEmpty
                            ? 'Untitled post'
                            : record.snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_subtitle(record)),
                      trailing: record.isScheduled
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Reschedule',
                                  icon: const Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    _reschedule(record, day);
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Cancel post',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    _cancel(record);
                                  },
                                ),
                              ],
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: record.isScheduled
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              _showRecordActions(record);
                            },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(FacebookPostRecord record) {
    if (!record.isScheduled) return 'Published';
    final at = record.scheduledAt;
    if (at == null) return 'Scheduled';
    final time = TimeOfDay.fromDateTime(at);
    return 'Scheduled for ${time.format(context)}';
  }

  Future<void> _showRecordActions(FacebookPostRecord record) async {
    final action = await FacebookPostActionsSheet.show(context, record);
    if (!mounted) return;
    switch (action) {
      case 'open':
        await openFacebookPost(
          context,
          record,
          missingMessage: record.isStoryOnlyPublished
              ? 'This Story has no feed post to open.'
              : null,
        );
      case 'copy':
        final uri = feedPostUri(record);
        if (uri == null) return;
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Link copied')));
      case 'delete':
        final error = await ref
            .read(facebookHistoryProvider.notifier)
            .deletePublishedPost(record.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error ?? 'Post deleted')));
    }
  }

  Future<void> _onDropRecord(FacebookPostRecord record, DateTime day) async {
    if (record.scheduledAt == null) return;
    final now = DateTime.now();
    final target = DateTime(day.year, day.month, day.day);
    final today = facebookCalendarDayKey(now);
    if (target.isBefore(today)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick a future day.')));
      return;
    }
    if (target.isAfter(today.add(FacebookDraftNotifier.maxScheduleLead))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduling is limited to 30 days ahead.'),
        ),
      );
      return;
    }
    await _reschedule(record, day);
  }

  static String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = ref.watch(facebookCalendarProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Content calendar',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _month = DateTime(now.year, now.month);
                _selectedDay = facebookCalendarDayKey(now);
              });
            },
            child: const Text('Today'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(facebookDraftProvider.notifier).reconcileScheduled(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            FacebookCalendarMonth(
              month: _month,
              selectedDay: _selectedDay,
              grouped: grouped,
              onSelectDay: (day) {
                setState(() => _selectedDay = day);
                _showDay(day);
              },
              onPreviousMonth: () => _shiftMonth(-1),
              onNextMonth: () => _shiftMonth(1),
              onToday: () {
                final now = DateTime.now();
                setState(() {
                  _month = DateTime(now.year, now.month);
                  _selectedDay = facebookCalendarDayKey(now);
                });
              },
              onDropRecord: (record, day) {
                _selectedDay = day;
                _onDropRecord(record, day);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Text('Scheduled', style: theme.textTheme.labelSmall),
                const SizedBox(width: AppSpacing.base),
                _LegendDot(color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Published', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me 10 minutes before'),
              subtitle: const Text(
                'Lock-screen reminders show only the scheduled time.',
              ),
              value: _remindersEnabled ?? false,
              onChanged: _remindersEnabled == null ? null : _toggleReminders,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (grouped.isEmpty)
              EmptyState(
                title: 'No posts yet',
                description:
                    'Scheduled and published posts will appear on their day.',
                icon: Icons.calendar_month_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
