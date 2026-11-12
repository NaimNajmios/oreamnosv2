import 'package:flutter/material.dart';

import 'package:oreamnos/domain/models/facebook_post_record.dart';

/// Shared bottom sheet listing everything you can do with a history record.
///
/// Returns the selected action key so the caller owns navigation and API
/// calls. Used by both the history screen and the Publish hub recent posts.
abstract final class FacebookPostActionsSheet {
  static Future<String?> show(BuildContext context, FacebookPostRecord record) {
    final errorColor = Theme.of(context).colorScheme.error;
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record.hasOpenableFeedPost)
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded, size: 20),
                  title: const Text('Open post'),
                  onTap: () => Navigator.pop(sheetContext, 'open'),
                ),
              if (record.hasOpenableFeedPost)
                ListTile(
                  leading: const Icon(Icons.link_rounded, size: 20),
                  title: const Text('Copy link'),
                  onTap: () => Navigator.pop(sheetContext, 'copy'),
                ),
              if (record.isStoryOnlyPublished)
                const ListTile(
                  leading: Icon(Icons.auto_stories_rounded, size: 20),
                  title: Text('Story only'),
                  subtitle: Text('This Story has no feed post to open.'),
                ),
              if (record.isPublished)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 20),
                  title: const Text('Edit caption'),
                  onTap: () => Navigator.pop(sheetContext, 'edit_caption'),
                ),
              if (record.isPublished)
                ListTile(
                  leading: const Icon(Icons.insights_rounded, size: 20),
                  title: const Text('View insights'),
                  onTap: () => Navigator.pop(sheetContext, 'view_insights'),
                ),
              if (record.isPublished && record.storyFailed)
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, size: 20),
                  title: const Text('Retry Story'),
                  onTap: () => Navigator.pop(sheetContext, 'retry_story'),
                ),
              if (record.isPublished)
                ListTile(
                  leading: const Icon(Icons.comment_outlined, size: 20),
                  title: const Text('Comments'),
                  onTap: () => Navigator.pop(sheetContext, 'comments'),
                ),
              if (record.isPublished)
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    size: 20,
                    color: errorColor,
                  ),
                  title: Text(
                    'Delete post',
                    style: TextStyle(color: errorColor),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'delete_post'),
                ),
              if (record.isScheduled)
                ListTile(
                  leading: const Icon(Icons.edit_calendar_rounded, size: 20),
                  title: const Text('Reschedule'),
                  onTap: () => Navigator.pop(sheetContext, 'reschedule'),
                ),
              if (record.isScheduled)
                ListTile(
                  leading: Icon(
                    Icons.event_busy_rounded,
                    size: 20,
                    color: errorColor,
                  ),
                  title: Text(
                    'Cancel schedule',
                    style: TextStyle(color: errorColor),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'cancel'),
                ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, size: 20),
                title: const Text('Copy caption'),
                onTap: () => Navigator.pop(sheetContext, 'copy_caption'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, size: 20),
                title: const Text('Reuse caption'),
                onTap: () => Navigator.pop(sheetContext, 'reuse'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: errorColor,
                ),
                title: Text(
                  'Remove from history',
                  style: TextStyle(color: errorColor),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
