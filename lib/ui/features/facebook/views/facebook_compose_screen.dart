import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';

/// Facebook-style composer: page identity, message first, compact media bar,
/// then a live feed preview that appears as soon as a photo is attached.
class FacebookComposeScreen extends ConsumerStatefulWidget {
  const FacebookComposeScreen({super.key});

  @override
  ConsumerState<FacebookComposeScreen> createState() =>
      _FacebookComposeScreenState();
}

class _FacebookComposeScreenState extends ConsumerState<FacebookComposeScreen> {
  late final TextEditingController _textController;
  bool _previewMode = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(facebookDraftProvider).text,
    );
    _textController.addListener(_syncText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final draft = ref.read(facebookDraftProvider);
      if (!draft.restoredFromStorage) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft restored'),
          action: SnackBarAction(
            label: 'Discard',
            onPressed: () {
              _textController.clear();
              ref.read(facebookDraftProvider.notifier).clearDraft();
            },
          ),
        ),
      );
    });
  }

  void _syncText() {
    ref.read(facebookDraftProvider.notifier).setDraftText(_textController.text);
  }

  @override
  void dispose() {
    _textController.removeListener(_syncText);
    _textController.dispose();
    super.dispose();
  }

  void _openConnectionDialog() {
    FacebookConnectionDialog.show(context);
  }

  Future<void> _openPermalink(String permalink) async {
    final uri = Uri.parse(permalink);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        Haptics.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  Future<void> _copyLink(String permalink) async {
    // Never copy through a log path — plain clipboard only.
    await Clipboard.setData(ClipboardData(text: permalink));
    if (!mounted) return;
    Haptics.lightImpact();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Post link copied')));
  }

  void _appendHashtags() {
    final appended = ref
        .read(facebookDraftProvider.notifier)
        .appendDefaultHashtags();
    if (!appended && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No default hashtag group yet — add one in Settings.'),
        ),
      );
    }
  }

  Future<void> _openMediaEditor(FacebookMediaItem initial) {
    final id = initial.identity;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final draft = ref.watch(facebookDraftProvider);
          final item = draft.mediaById(id);
          if (item == null) {
            return const SizedBox(height: 200);
          }
          final index = draft.media.indexWhere((m) => m.identity == id);
          final notifier = ref.read(facebookDraftProvider.notifier);
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.xs,
                AppSpacing.base,
                AppSpacing.base + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.base,
                children: [
                  Text(
                    'Photo ${index + 1} of ${draft.media.length}',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusMd,
                    child: PreviewImage(
                      imagePath: item.path,
                      aspect: item.aspect,
                      zoom: item.zoom,
                      offset: item.offset,
                      onCropChanged: (zoom, offset) =>
                          notifier.updateMedia(id, zoom: zoom, offset: offset),
                    ),
                  ),
                  AspectSelector(
                    selected: item.aspect,
                    onSelected: (aspect) =>
                        notifier.updateMedia(id, aspect: aspect),
                  ),
                  CropZoomSlider(
                    zoom: item.zoom,
                    onChanged: (zoom) => notifier.updateMedia(id, zoom: zoom),
                    onReset: () => notifier.resetMediaCrop(id),
                  ),
                  AltTextField(
                    value: item.altText,
                    onChanged: (value) =>
                        notifier.updateMedia(id, altText: value),
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      OutlinedButton.icon(
                        onPressed: index <= 0
                            ? null
                            : () => notifier.makeCover(id),
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: const Text('Make cover'),
                      ),
                      OutlinedButton.icon(
                        onPressed: index <= 0
                            ? null
                            : () => notifier.moveMedia(index, index - 1),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Move left'),
                      ),
                      OutlinedButton.icon(
                        onPressed: index >= draft.media.length - 1
                            ? null
                            : () => notifier.moveMedia(index, index + 1),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Move right'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          notifier.removeMedia(id);
                          Navigator.of(sheetContext).pop();
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        label: Text(
                          'Remove photo',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final draft = ref.read(facebookDraftProvider);
    final initial = draft.scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(FacebookDraftNotifier.maxScheduleLead),
      helpText: 'Schedule post',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Choose a time',
    );
    if (time == null || !mounted) return;
    final at = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final error = FacebookDraftNotifier.scheduleValidationError(at);
    if (error != null) {
      Haptics.lightImpact();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ref.read(facebookDraftProvider.notifier).setScheduledAt(at);
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard draft?'),
        content: const Text(
          'Your caption and photo have not been published. Discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(facebookDraftProvider);
    final connection = ref.watch(facebookViewModelProvider);

    ref.listen<FacebookComposePhase>(
      facebookDraftProvider.select((s) => s.phase),
      (prev, next) {
        if (next == FacebookComposePhase.published &&
            prev != FacebookComposePhase.published) {
          Haptics.mediumImpact();
        }
      },
    );

    final published = draft.isFinished && draft.result != null;
    final hasUnsavedDraft =
        !draft.isFinished && (draft.hasText || draft.hasImage);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canPublish = draft.canPublish && connection.isConnected;
    final needsConnection = connection.isNotConnected || connection.isExpired;

    return PopScope(
      canPop: _allowPop || !hasUnsavedDraft,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard();
        if (!shouldDiscard || !mounted) return;
        ref.read(facebookDraftProvider.notifier).clearDraft();
        setState(() => _allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (!context.mounted) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            draft.isScheduled
                ? 'Scheduled'
                : published
                ? 'Published'
                : _previewMode
                ? 'Post preview'
                : 'Create post',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            if (!published)
              IconButton(
                tooltip: _previewMode ? 'Back to editing' : 'Preview post',
                icon: Icon(
                  _previewMode
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _previewMode = !_previewMode),
              ),
          ],
        ),
        bottomNavigationBar: published
            ? null
            : AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: keyboardOpen
                    ? const SizedBox(width: double.infinity)
                    : _ComposeActionBar(
                        draft: draft,
                        pageName: connection.pageName,
                        canPublish: canPublish,
                        needsConnection: needsConnection,
                        onPost: () {
                          if (needsConnection) {
                            _openConnectionDialog();
                            return;
                          }
                          ref.read(facebookDraftProvider.notifier).publish();
                        },
                        onModeChanged: (mode) => ref
                            .read(facebookDraftProvider.notifier)
                            .setPublishMode(mode),
                        onPickSchedule: _pickSchedule,
                      ),
              ),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: published
                  ? _SuccessView(
                      draft: draft,
                      pageName: connection.pageName,
                      pagePictureUrl: connection.pagePictureUrl,
                      onView: () => _openPermalink(draft.result!.permalink),
                      onCopy: () => _copyLink(draft.result!.permalink),
                      onCopyCaption: () async {
                        await Clipboard.setData(
                          ClipboardData(text: draft.text),
                        );
                        if (!context.mounted) return;
                        Haptics.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Caption copied')),
                        );
                      },
                      onCancelSchedule: draft.isScheduled
                          ? () async {
                              final error = await ref
                                  .read(facebookDraftProvider.notifier)
                                  .cancelScheduledPost(draft.result!.postId);
                              if (!context.mounted) return;
                              if (error != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                                return;
                              }
                              _textController.clear();
                              ref
                                  .read(facebookDraftProvider.notifier)
                                  .resetForAnotherPost();
                            }
                          : null,
                      onPublishAnother: () {
                        _textController.clear();
                        ref
                            .read(facebookDraftProvider.notifier)
                            .resetForAnotherPost();
                        setState(() => _previewMode = false);
                      },
                      onDone: () => context.pop(),
                    )
                  : _previewMode
                  ? _PreviewMode(
                      draft: draft,
                      pageName: connection.pageName,
                      pagePictureUrl: connection.pagePictureUrl,
                      onBack: () => setState(() => _previewMode = false),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.base,
                        AppSpacing.base,
                        AppSpacing.base,
                        AppSpacing.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.base,
                        children: [
                          PageIdentityRow(
                            pageName: connection.pageName,
                            pagePictureUrl: connection.pagePictureUrl,
                            needsConnection: needsConnection,
                            onTap: _openConnectionDialog,
                          ),
                          _ComposerCard(
                            controller: _textController,
                            draft: draft,
                            onGallery: () => ref
                                .read(facebookDraftProvider.notifier)
                                .attachImages(ImageSource.gallery),
                            onCamera: () => ref
                                .read(facebookDraftProvider.notifier)
                                .attachImage(ImageSource.camera),
                            onHashtags: _appendHashtags,
                            onRemoveMedia: (id) => ref
                                .read(facebookDraftProvider.notifier)
                                .removeMedia(id),
                            onEditMedia: (item) => _openMediaEditor(item),
                          ),
                          if (draft.phase ==
                                  FacebookComposePhase.publishError &&
                              draft.error != null)
                            _ErrorPanel(
                              message: draft.error!.message,
                              needsReconnect: draft.error!.needsReconnect,
                              onRetry: () => ref
                                  .read(facebookDraftProvider.notifier)
                                  .publish(),
                              onReconnect: _openConnectionDialog,
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.controller,
    required this.draft,
    required this.onGallery,
    required this.onCamera,
    required this.onHashtags,
    required this.onRemoveMedia,
    required this.onEditMedia,
  });

  final TextEditingController controller;
  final FacebookComposeState draft;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onHashtags;
  final ValueChanged<String> onRemoveMedia;
  final ValueChanged<FacebookMediaItem> onEditMedia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppSpacing.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            decoration: InputDecoration(
              hintText: "What's on your mind?",
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.base),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.base,
              right: AppSpacing.base,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  '${draft.text.length} chars',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (draft.text.length > 125)
                  Text(
                    'Feed shows ~125, then See more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (draft.media.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: ClipRRect(
                borderRadius: AppSpacing.borderRadiusMd,
                child: MediaCarousel(
                  media: draft.media,
                  onEdit: onEditMedia,
                  onRemove: onRemoveMedia,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                0,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Text(
                draft.media.length > 1
                    ? 'Swipe between photos · edit to crop, reorder or add alt text'
                    : 'Tap edit to crop, zoom or add alt text',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          ],
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: MediaActionBar(
              onGallery: onGallery,
              onCamera: onCamera,
              onHashtags: onHashtags,
              mediaCount: draft.media.length,
              canAddPhoto: draft.canAddMoreMedia,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMode extends StatelessWidget {
  const _PreviewMode({
    required this.draft,
    required this.pageName,
    required this.pagePictureUrl,
    required this.onBack,
  });

  final FacebookComposeState draft;
  final String pageName;
  final String pagePictureUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.base,
        children: [
          PostPreviewCard(
            pageName: pageName,
            pagePictureUrl: pagePictureUrl,
            message: draft.text,
            media: draft.media,
            imagePath: draft.imagePath,
            imageAspect: draft.imageAspect,
            imageZoom: draft.mediaItem?.zoom ?? 1.0,
            imageOffset: draft.mediaItem?.offset ?? Offset.zero,
            imageAltText: draft.mediaItem?.altText ?? '',
            maxMessageLines: 40,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Back to editing'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeActionBar extends StatelessWidget {
  const _ComposeActionBar({
    required this.draft,
    required this.pageName,
    required this.canPublish,
    required this.needsConnection,
    required this.onPost,
    required this.onModeChanged,
    required this.onPickSchedule,
  });

  final FacebookComposeState draft;
  final String pageName;
  final bool canPublish;
  final bool needsConnection;
  final VoidCallback onPost;
  final ValueChanged<FacebookPublishMode> onModeChanged;
  final VoidCallback onPickSchedule;

  static String _progressCopy(double progress, int count) {
    if (progress <= 0) {
      return count > 1 ? 'Preparing photos…' : 'Preparing photo…';
    }
    final percent = (progress * 100).round();
    if (count <= 1) return 'Uploading photo · $percent%';
    final index = (progress * count).ceil().clamp(1, count);
    return 'Uploading photo $index of $count · $percent%';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = pageName.trim().isEmpty ? 'Facebook' : pageName;
    final progress = draft.uploadProgress;
    final scheduled = draft.publishMode == FacebookPublishMode.scheduled;
    final scheduledAt = draft.scheduledAt;
    final scheduleLabel = scheduledAt == null
        ? 'Choose date & time'
        : _formatSchedule(scheduledAt);

    final label = needsConnection
        ? 'Connect Page to post'
        : draft.isPublishing
        ? (draft.media.length > 1
              ? 'Uploading photos…'
              : (draft.hasImage ? 'Uploading photo…' : 'Publishing…'))
        : scheduled
        ? 'Schedule for $scheduleLabel'
        : 'Post to $target';

    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.isPublishing && progress != null) ...[
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusPill,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _progressCopy(progress, draft.media.length),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: SegmentedButton<FacebookPublishMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: FacebookPublishMode.now,
                      label: Text('Post now'),
                      icon: Icon(Icons.send_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: FacebookPublishMode.scheduled,
                      label: Text('Schedule'),
                      icon: Icon(Icons.schedule_rounded, size: 16),
                    ),
                  ],
                  selected: {draft.publishMode},
                  onSelectionChanged: (selection) =>
                      onModeChanged(selection.first),
                ),
              ),
            ],
          ),
          if (scheduled) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onPickSchedule,
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text(scheduleLabel),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Device time · Facebook schedules at least 10 minutes ahead.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: label,
            isLoading: draft.isPublishing,
            onPressed: canPublish || needsConnection ? onPost : null,
            icon: scheduled ? Icons.schedule_rounded : Icons.public_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Publishes publicly as your Page. Markdown has been stripped.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatSchedule(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '${at.month}/${at.day} $h:$m';
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.draft,
    required this.pageName,
    required this.pagePictureUrl,
    required this.onView,
    required this.onCopy,
    required this.onCopyCaption,
    required this.onPublishAnother,
    required this.onDone,
    this.onCancelSchedule,
  });

  final FacebookComposeState draft;
  final String pageName;
  final String pagePictureUrl;
  final VoidCallback onView;
  final VoidCallback onCopy;
  final VoidCallback onCopyCaption;
  final VoidCallback onPublishAnother;
  final VoidCallback onDone;
  final VoidCallback? onCancelSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = pageName.trim().isEmpty ? 'your Page' : pageName;
    final scheduled = draft.isScheduled;
    final at = draft.scheduledAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.base,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              scheduled ? Icons.schedule_rounded : Icons.check_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            scheduled ? 'Post scheduled' : 'Your post is live',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            scheduled
                ? 'Will publish to $target on ${_formatSchedule(at)}'
                : 'Published to $target',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          PostPreviewCard(
            pageName: pageName,
            pagePictureUrl: pagePictureUrl,
            message: draft.text,
            media: draft.media,
            imagePath: draft.imagePath,
            imageAspect: draft.imageAspect,
            imageZoom: draft.mediaItem?.zoom ?? 1.0,
            imageOffset: draft.mediaItem?.offset ?? Offset.zero,
            imageAltText: draft.mediaItem?.altText ?? '',
            maxMessageLines: 6,
          ),
          if (!scheduled)
            AppButton(
              label: 'View on Facebook',
              icon: Icons.open_in_new_rounded,
              onPressed: onView,
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!scheduled)
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copy link'),
                ),
              if (!scheduled) const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: onCopyCaption,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy caption'),
              ),
            ],
          ),
          if (scheduled && onCancelSchedule != null)
            TextButton.icon(
              onPressed: onCancelSchedule,
              icon: Icon(
                Icons.event_busy_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              label: Text(
                'Cancel schedule',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          TextButton.icon(
            onPressed: onPublishAnother,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Publish another'),
          ),
          TextButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }

  static String _formatSchedule(DateTime? at) {
    if (at == null) return 'a later time';
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '${at.month}/${at.day} $h:$m';
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.needsReconnect,
    required this.onRetry,
    required this.onReconnect,
  });

  final String message;
  final bool needsReconnect;
  final VoidCallback onRetry;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      borderRadius: AppSpacing.borderRadiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          needsReconnect
              ? TextButton.icon(
                  onPressed: onReconnect,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reconnect Page'),
                )
              : TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
        ],
      ),
    );
  }
}
