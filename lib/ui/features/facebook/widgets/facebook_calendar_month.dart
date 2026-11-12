import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/facebook_post_record.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_calendar_view_model.dart';

/// Month grid for the content calendar. Tap is the primary interaction;
/// long-press starts a supplementary drag for scheduled posts.
class FacebookCalendarMonth extends StatelessWidget {
  const FacebookCalendarMonth({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.grouped,
    required this.onSelectDay,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onDropRecord,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final Map<DateTime, List<FacebookPostRecord>> grouped;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final void Function(FacebookPostRecord record, DateTime day) onDropRecord;

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grid = facebookCalendarMonthGrid(month);
    final today = facebookCalendarDayKey(DateTime.now());

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '${_monthName(month.month)} ${month.year}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Row(
          children: [
            for (final label in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grid.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final day = grid[index];
            if (day == null) return const SizedBox.shrink();
            final records = grouped[day] ?? const <FacebookPostRecord>[];
            final scheduled = records.where((r) => r.isScheduled).toList();
            final selected = selectedDay != null && day == selectedDay;
            final isToday = day == today;
            return _DayCell(
              day: day,
              records: records,
              scheduled: scheduled,
              selected: selected,
              isToday: isToday,
              onTap: () {
                Haptics.lightImpact();
                onSelectDay(day);
              },
              onDropRecord: onDropRecord,
            );
          },
        ),
      ],
    );
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
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.records,
    required this.scheduled,
    required this.selected,
    required this.isToday,
    required this.onTap,
    required this.onDropRecord,
  });

  final DateTime day;
  final List<FacebookPostRecord> records;
  final List<FacebookPostRecord> scheduled;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;
  final void Function(FacebookPostRecord record, DateTime day) onDropRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dots = records.take(3).toList();
    final extra = records.length - dots.length;
    final scheduledCount = scheduled.length;
    final publishedCount = records.length - scheduledCount;
    final semantics = StringBuffer(
      '${day.day} ${FacebookCalendarMonth._monthName(day.month)}',
    );
    if (scheduledCount > 0) {
      semantics.write(
        ', $scheduledCount scheduled '
        '${scheduledCount == 1 ? 'post' : 'posts'}',
      );
    }
    if (publishedCount > 0) {
      semantics.write(
        ', $publishedCount published '
        '${publishedCount == 1 ? 'post' : 'posts'}',
      );
    }

    Widget cell = InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Semantics(
        button: true,
        label: semantics.toString(),
        selected: selected,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusMd,
            border: isToday
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 2,
                children: [
                  for (final record in dots)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: record.isScheduled
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.primary,
                      ),
                    ),
                  if (extra > 0)
                    Text(
                      '+$extra',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (scheduled.isNotEmpty) {
      cell = LongPressDraggable<FacebookPostRecord>(
        data: scheduled.first,
        feedback: Material(
          elevation: 4,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              scheduled.first.snippet.isEmpty
                  ? 'Scheduled post'
                  : scheduled.first.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: cell),
        child: cell,
      );
    }

    return DragTarget<FacebookPostRecord>(
      onWillAcceptWithDetails: (details) =>
          details.data.isScheduled && details.data.scheduledAt != null,
      onAcceptWithDetails: (details) => onDropRecord(details.data, day),
      builder: (context, candidates, rejected) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            border: candidates.isEmpty
                ? null
                : Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: cell,
        );
      },
    );
  }
}
