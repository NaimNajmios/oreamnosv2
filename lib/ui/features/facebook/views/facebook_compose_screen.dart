import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_workflow_store.dart';
import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/posting_time_slot.dart';
import 'package:oreamnos/domain/services/best_time_to_post.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/utils/facebook_external_links.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_success_view.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_banner.dart';
import 'package:oreamnos/ui/features/facebook/widgets/facebook_connection_dialog.dart';
import 'package:oreamnos/ui/features/facebook/widgets/page_switcher_sheet.dart';
import 'package:oreamnos/ui/features/publish/view_models/facebook_performance_view_model.dart';
import 'package:oreamnos/ui/features/publish/view_models/publish_handoff_view_model.dart';

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
  bool _suppressPageMismatch = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(facebookDraftProvider).text,
    );
    _textController.addListener(_syncText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(facebookViewModelProvider.notifier).checkConnectionHealth();
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

  void _openHistoryTab(String tab) {
    context.push('${RoutePaths.facebookHistory}?tab=$tab');
  }

  Future<void> _retryAfterUncertain() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Try publishing again?'),
        content: const Text(
          'If the previous attempt actually reached Facebook, retrying can '
          'create a duplicate post. Check Published first if unsure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Check first'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Publish again'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(facebookDraftProvider.notifier).publish();
  }

  Future<void> _openWorkflowSheet() async {
    final connection = ref.read(facebookViewModelProvider);
    final store = getIt<FacebookWorkflowStore>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final draft = ref.watch(facebookDraftProvider);
          final workflows = store.forPage(connection.activePageId);
          final defaultId = store.defaultForPage(connection.activePageId).id;
          return SafeArea(
            child: SingleChildScrollView(
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
                    'Publishing workflow',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final workflow in workflows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        workflow.storyEnabled
                            ? Icons.auto_stories_rounded
                            : Icons.article_outlined,
                      ),
                      title: Text(workflow.name),
                      subtitle: Text(workflow.destinationLabel),
                      trailing: workflow.id == defaultId
                          ? Icon(
                              Icons.star_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(facebookDraftProvider.notifier)
                            .applyWorkflow(workflow);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.tune_rounded),
                    title: const Text('Customize this post'),
                    subtitle: const Text(
                      'Toggle Page/Story and edit the title',
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(),
                  ),
                  if (draft.workflowId.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.star_outline_rounded),
                      title: const Text('Make default for this Page'),
                      onTap: () async {
                        await store.setDefaultForPage(
                          connection.activePageId,
                          draft.workflowId,
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Manage workflows'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await context.push(RoutePaths.facebookWorkflows);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPageSwitcher() {
    final connection = ref.read(facebookViewModelProvider);
    if (connection.pages.isEmpty) {
      FacebookConnectionDialog.show(context);
    } else {
      PageSwitcherSheet.show(context);
    }
  }

  String _pageNameFor(String pageId) {
    for (final page in ref.read(facebookViewModelProvider).pages) {
      if (page.id == pageId) {
        return page.name.isEmpty ? 'this Page' : page.name;
      }
    }
    return 'this Page';
  }

  Future<void> _handlePageChange(String? previous, String next) async {
    if (next.isEmpty || _suppressPageMismatch) return;
    final notifier = ref.read(facebookDraftProvider.notifier);
    final draft = ref.read(facebookDraftProvider);
    if (draft.isEmpty || draft.pageId == next || draft.pageId.isEmpty) {
      notifier.retargetDraft(next, pageName: _pageNameFor(next));
      return;
    }
    final targetName = _pageNameFor(next);
    final draftName = _pageNameFor(draft.pageId);
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Draft belongs to another Page'),
        content: Text(
          'This draft was written for $draftName. Posting it to $targetName '
          'will use the new Page. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Keep original Page'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('duplicate'),
            child: const Text('Duplicate draft'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('switch'),
            child: const Text('Switch target'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'duplicate':
        await notifier.duplicateDraftForPage(
          next,
          pageName: _pageNameFor(next),
        );
        if (mounted) {
          _textController.text = ref.read(facebookDraftProvider).text;
        }
        break;
      case 'switch':
        notifier.retargetDraft(next, pageName: _pageNameFor(next));
        break;
      case 'cancel':
        if (previous != null && previous.isNotEmpty) {
          _suppressPageMismatch = true;
          await ref
              .read(facebookViewModelProvider.notifier)
              .switchPage(previous);
          _suppressPageMismatch = false;
        }
        break;
      default:
        break;
    }
  }

  Future<void> _openPermalink(String permalink) async {
    await openFacebookPermalink(
      context,
      permalink,
      missingMessage: 'This Story has no feed post to open.',
    );
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
    final draft = ref.read(facebookDraftProvider);
    final slots = ref.read(bestTimeToPostProvider);
    final at = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ScheduleSheet(
        initial:
            draft.scheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
        suggestions: slots,
      ),
    );
    if (at == null || !mounted) return;
    ref.read(facebookDraftProvider.notifier).setScheduledAt(at);
  }

  Future<String?> _promptCloseDraft() {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this draft?'),
        content: const Text(
          'Save it to Drafts to finish later, or discard it for good.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('keep'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );
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
        final finished =
            next == FacebookComposePhase.published ||
            next == FacebookComposePhase.scheduled ||
            next == FacebookComposePhase.partialSuccess;
        if (finished && prev != next) {
          ref.read(publishHandoffProvider.notifier).consume();
        }
      },
    );
    ref.listen<String>(
      facebookViewModelProvider.select((s) => s.activePageId),
      (prev, next) {
        if (prev != null && prev != next) {
          _handlePageChange(prev, next);
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
        final choice = await _promptCloseDraft();
        if (choice == null || choice == 'keep' || !mounted) return;
        final notifier = ref.read(facebookDraftProvider.notifier);
        if (choice == 'save') {
          await notifier.saveDraftNow();
        } else {
          notifier.clearDraft();
        }
        if (!mounted) return;
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
                tooltip: 'Drafts',
                icon: const Icon(Icons.drafts_outlined, size: 20),
                onPressed: () async {
                  await context.push(RoutePaths.facebookDrafts);
                  if (!mounted) return;
                  _textController.text = ref.read(facebookDraftProvider).text;
                },
              ),
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
                  ? FacebookSuccessView(
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
                            onTap: _openPageSwitcher,
                          ),
                          if (connection.offline || connection.isExpired)
                            FacebookConnectionBanner(
                              offline: connection.offline,
                              expired: connection.isExpired,
                              onRetry: () => ref
                                  .read(facebookViewModelProvider.notifier)
                                  .checkConnectionHealth(force: true),
                              onReconnect: _openConnectionDialog,
                            ),
                          _WorkflowBar(draft: draft, onTap: _openWorkflowSheet),
                          if (draft.storyEnabled)
                            _StoryCard(
                              draft: draft,
                              onChanged: (value) => ref
                                  .read(facebookDraftProvider.notifier)
                                  .setStoryEnabled(value),
                              onTitleChanged: (value) => ref
                                  .read(facebookDraftProvider.notifier)
                                  .setStoryTitle(value),
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
                          if (draft.phase ==
                                  FacebookComposePhase.publishUncertain &&
                              draft.error != null)
                            _UncertainPanel(
                              message: draft.error!.message,
                              onViewPublished: () =>
                                  _openHistoryTab('published'),
                              onViewScheduled: () =>
                                  _openHistoryTab('scheduled'),
                              onRetry: _retryAfterUncertain,
                              onDiscard: () => ref
                                  .read(facebookDraftProvider.notifier)
                                  .clearDraft(),
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

class _PreviewMode extends StatefulWidget {
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
  State<_PreviewMode> createState() => _PreviewModeState();
}

class _PreviewModeState extends State<_PreviewMode> {
  Brightness _brightness = Brightness.light;
  bool _visitor = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.colorScheme.primary,
        brightness: _brightness,
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.base,
        children: [
          Row(
            children: [
              SegmentedButton<Brightness>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: Brightness.light,
                    icon: Icon(Icons.light_mode_outlined, size: 16),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: Brightness.dark,
                    icon: Icon(Icons.dark_mode_outlined, size: 16),
                    label: Text('Dark'),
                  ),
                ],
                selected: {_brightness},
                onSelectionChanged: (selection) {
                  setState(() => _brightness = selection.first);
                },
              ),
              const Spacer(),
              FilterChip(
                selected: _visitor,
                label: const Text('Visitor view'),
                onSelected: (value) => setState(() => _visitor = value),
              ),
            ],
          ),
          if (_visitor)
            Text(
              'Visitor view hides editing affordances.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          Theme(
            data: previewTheme,
            child: PostPreviewCard(
              pageName: widget.pageName,
              pagePictureUrl: widget.pagePictureUrl,
              message: widget.draft.text,
              media: widget.draft.media,
              imagePath: widget.draft.imagePath,
              imageAspect: widget.draft.imageAspect,
              imageZoom: widget.draft.mediaItem?.zoom ?? 1.0,
              imageOffset: widget.draft.mediaItem?.offset ?? Offset.zero,
              imageAltText: widget.draft.mediaItem?.altText ?? '',
              maxMessageLines: 40,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Back to editing'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.initial, this.suggestions = const []});

  final DateTime initial;
  final List<PostingTimeSlot> suggestions;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
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

class _WorkflowBar extends StatelessWidget {
  const _WorkflowBar({required this.draft, required this.onTap});

  final FacebookComposeState draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = draft.workflowName.isNotEmpty
        ? draft.workflowName
        : draft.storyEnabled
        ? 'Page + Story'
        : 'Page post';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            draft.storyEnabled
                ? Icons.auto_stories_rounded
                : Icons.article_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            draft.publishFeed && draft.storyEnabled
                ? 'Page + Story'
                : draft.storyEnabled
                ? 'Story only'
                : 'Page only',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatefulWidget {
  const _StoryCard({
    required this.draft,
    required this.onChanged,
    required this.onTitleChanged,
  });

  final FacebookComposeState draft;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onTitleChanged;

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.draft.storyTitle);
  }

  @override
  void didUpdateWidget(covariant _StoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.draft.storyTitle != _title.text &&
        widget.draft.storyTitle.isNotEmpty) {
      _title.text = widget.draft.storyTitle;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _title.text.trim();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Story',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: widget.draft.storyEnabled,
                onChanged: widget.onChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppSpacing.borderRadiusMd,
                child: Container(
                  width: 84,
                  height: 149,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B3D91), Color(0xFF6D28D9)],
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title.isEmpty ? 'Story title' : title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _title,
                      maxLength: 100,
                      maxLines: 3,
                      minLines: 1,
                      onChanged: widget.onTitleChanged,
                      decoration: const InputDecoration(
                        labelText: 'Story title',
                        hintText: 'Short headline, not the full caption',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    Text(
                      widget.draft.media.isEmpty
                          ? 'No photo attached: a gradient Story card will be generated.'
                          : 'Uses the cover photo. The full caption stays on the Page post.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        : draft.isPreparing
        ? 'Preparing photos…'
        : draft.isPublishing
        ? (draft.media.length > 1
              ? 'Uploading photos…'
              : (draft.hasImage ? 'Uploading photo…' : 'Publishing…'))
        : scheduled
        ? 'Schedule for $scheduleLabel'
        : !draft.publishFeed && draft.storyEnabled
        ? 'Post Story'
        : draft.storyEnabled
        ? 'Post to $target + Story'
        : 'Post to $target';

    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((draft.isPublishing || draft.isPreparing) &&
              progress != null) ...[
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
              draft.isPreparing
                  ? 'Preparing photos…'
                  : _progressCopy(progress, draft.media.length),
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

class _UncertainPanel extends StatelessWidget {
  const _UncertainPanel({
    required this.message,
    required this.onViewPublished,
    required this.onViewScheduled,
    required this.onRetry,
    required this.onDiscard,
  });

  final String message;
  final VoidCallback onViewPublished;
  final VoidCallback onViewScheduled;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

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
                Icons.help_outline_rounded,
                size: 18,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'We didn’t get a confirmation from Facebook. The post may or may '
            'not be live. Check Published before trying again.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              TextButton(
                onPressed: onViewPublished,
                child: const Text('View Published'),
              ),
              TextButton(
                onPressed: onViewScheduled,
                child: const Text('View Scheduled'),
              ),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
              TextButton(
                onPressed: onDiscard,
                child: Text(
                  'Discard',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
