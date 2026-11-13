import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_workflow_store.dart';
import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';
import 'package:oreamnos/ui/features/facebook/utils/facebook_external_links.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_compose_action_bar.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_compose_panels.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_composer_card.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_draft_save_status.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_preview_mode.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_schedule_sheet.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_story_card.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_success_view.dart';
import 'package:oreamnos/ui/features/facebook/views/compose/facebook_workflow_bar.dart';
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
      ref.read(facebookDraftProvider.notifier).acknowledgeRestore();
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
      builder: (_) => FacebookScheduleSheet(
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
                    : FacebookComposeActionBar(
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
                  ? FacebookPreviewMode(
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
                          FacebookWorkflowBar(
                            draft: draft,
                            onTap: _openWorkflowSheet,
                          ),
                          if (draft.storyEnabled)
                            FacebookStoryCard(
                              draft: draft,
                              onChanged: (value) => ref
                                  .read(facebookDraftProvider.notifier)
                                  .setStoryEnabled(value),
                              onTitleChanged: (value) => ref
                                  .read(facebookDraftProvider.notifier)
                                  .setStoryTitle(value),
                            ),
                          FacebookComposerCard(
                            controller: _textController,
                            draft: draft,
                            onGallery: () async {
                              final result = await ref
                                  .read(facebookDraftProvider.notifier)
                                  .attachImages(ImageSource.gallery);
                              if (!context.mounted) return;
                              if (result is MediaAttachFailed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.message)),
                                );
                              }
                            },
                            onCamera: () async {
                              if (draft.media.isNotEmpty) {
                                final replace = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Replace photos?'),
                                    content: const Text(
                                      'Taking a new photo replaces every photo currently attached.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext)
                                                .pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext)
                                                .pop(true),
                                        child: const Text('Replace'),
                                      ),
                                    ],
                                  ),
                                );
                                if (replace != true || !mounted) return;
                              }
                              final result = await ref
                                  .read(facebookDraftProvider.notifier)
                                  .attachImage(ImageSource.camera);
                              if (!context.mounted) return;
                              if (result is MediaAttachFailed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.message)),
                                );
                              }
                            },
                            onHashtags: _appendHashtags,
                            onRemoveMedia: (id) => ref
                                .read(facebookDraftProvider.notifier)
                                .removeMedia(id),
                            onEditMedia: (item) => _openMediaEditor(item),
                          ),
                          if (!draft.isEmpty && !draft.isFinished)
                            FacebookDraftSaveStatus(
                              state: draft.draftSaveState,
                              savedAt: draft.lastDraftSavedAt,
                              onRetry: () => ref
                                  .read(facebookDraftProvider.notifier)
                                  .saveDraftNow(),
                            ),
                          if (draft.phase ==
                                  FacebookComposePhase.publishError &&
                              draft.error != null)
                            FacebookErrorPanel(
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
                            FacebookUncertainPanel(
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
