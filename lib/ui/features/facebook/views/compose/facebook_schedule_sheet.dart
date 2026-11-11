import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/posting_time_slot.dart';
import 'package:oreamnos/domain/services/best_time_to_post.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

/// Date/time picker for a scheduled Page post.
class FacebookScheduleSheet extends StatefulWidget {
  const FacebookScheduleSheet({
    super.key,
    required this.initial,
    this.suggestions = const [],
  });

  final DateTime initial;
  final List<PostingTimeSlot> suggestions;

  @override
  State<FacebookScheduleSheet> createState() => _FacebookScheduleSheetState();
}

class _FacebookScheduleSheetState extends State<FacebookScheduleSheet> {
  late DateTime _selected = widget.initial;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: now,
      lastDate: now.add(FacebookDraftNotifier.maxScheduleLead),
      helpText: 'Schedule post',
    );
    if (date == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        date.year,
        date.month,
        date.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
      helpText: 'Choose a time',
    );
    if (time == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        _selected.year,
        _selected.month,
        _selected.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = FacebookDraftNotifier.scheduleValidationError(_selected);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Schedule post',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Stories can’t be scheduled. This schedules the Page post.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            if (widget.suggestions.isNotEmpty) ...[
              Text(
                'Suggested from your own posts',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final slot in widget.suggestions)
                    ActionChip(
                      label: Text(slot.label),
                      onPressed: () => setState(
                        () => _selected = BestTimeToPost.nextOccurrence(slot),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Date'),
              trailing: Text(
                '${_selected.month}/${_selected.day}/${_selected.year}',
                style: theme.textTheme.bodyMedium,
              ),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Time'),
              trailing: Text(
                TimeOfDay.fromDateTime(_selected).format(context),
                style: theme.textTheme.bodyMedium,
              ),
              onTap: _pickTime,
            ),
            Text(
              'Device timezone: ${_selected.timeZoneName}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.base),
            AppButton(
              label: 'Schedule post',
              onPressed: error == null
                  ? () => Navigator.of(context).pop(_selected)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
