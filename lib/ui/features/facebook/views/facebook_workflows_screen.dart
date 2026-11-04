import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_workflow_store.dart';
import 'package:oreamnos/domain/models/facebook_publish_workflow.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_button.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_view_model.dart';

/// Manage publishing workflows and the default for the active Page.
class FacebookWorkflowsScreen extends ConsumerStatefulWidget {
  const FacebookWorkflowsScreen({super.key});

  @override
  ConsumerState<FacebookWorkflowsScreen> createState() =>
      _FacebookWorkflowsScreenState();
}

class _FacebookWorkflowsScreenState
    extends ConsumerState<FacebookWorkflowsScreen> {
  late final FacebookWorkflowStore _store;
  late String _pageId;
  List<FacebookPublishWorkflow> _workflows = const [];
  String _defaultId = '';

  @override
  void initState() {
    super.initState();
    _store = getIt<FacebookWorkflowStore>();
    _pageId = ref.read(facebookViewModelProvider).activePageId;
    _load();
  }

  void _load() {
    setState(() {
      _workflows = _store.forPage(_pageId);
      _defaultId = _store.defaultForPage(_pageId).id;
    });
  }

  Future<void> _edit(FacebookPublishWorkflow? workflow) async {
    final result = await showModalBottomSheet<FacebookPublishWorkflow>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WorkflowEditor(
        workflow:
            workflow ??
            FacebookPublishWorkflow(
              id: const Uuid().v4(),
              name: 'New workflow',
              pageId: _pageId,
            ),
      ),
    );
    if (result == null || !mounted) return;
    await _store.save(result);
    _load();
  }

  Future<void> _delete(FacebookPublishWorkflow workflow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete workflow?'),
        content: Text('"${workflow.name}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _store.delete(workflow.id);
    _load();
  }

  Future<void> _setDefault(FacebookPublishWorkflow workflow) async {
    await _store.setDefaultForPage(_pageId, workflow.id);
    Haptics.lightImpact();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Publishing workflows',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New workflow'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.base),
        itemCount: _workflows.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                'The default applies when a new draft starts. You can still '
                'change the workflow per post.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final workflow = _workflows[index - 1];
          final selected = workflow.id == _defaultId;
          return AppCard(
            onTap: () => _setDefault(workflow),
            child: Row(
              children: [
                Icon(
                  workflow.storyEnabled
                      ? Icons.auto_stories_rounded
                      : Icons.article_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workflow.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${workflow.destinationLabel} · '
                        '${workflow.pageId.isEmpty ? 'Any Page' : 'This Page'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
                if (!workflow.builtIn)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _edit(workflow);
                      } else if (value == 'delete') {
                        _delete(workflow);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkflowEditor extends StatefulWidget {
  const _WorkflowEditor({required this.workflow});

  final FacebookPublishWorkflow workflow;

  @override
  State<_WorkflowEditor> createState() => _WorkflowEditorState();
}

class _WorkflowEditorState extends State<_WorkflowEditor> {
  late final TextEditingController _name;
  late final TextEditingController _customTitle;
  late bool _feed;
  late bool _story;
  late bool _customTitleEnabled;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.workflow.name);
    _customTitle = TextEditingController(text: widget.workflow.customTitle);
    _feed = widget.workflow.publishFeed;
    _story = widget.workflow.storyEnabled;
    _customTitleEnabled =
        widget.workflow.storyTitleSource == FacebookStoryTitleSource.custom;
  }

  @override
  void dispose() {
    _name.dispose();
    _customTitle.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty || (!_feed && !_story)) return;
    Navigator.of(context).pop(
      widget.workflow.copyWith(
        name: name,
        publishFeed: _feed,
        storyEnabled: _story,
        storyTitleSource: _customTitleEnabled
            ? FacebookStoryTitleSource.custom
            : FacebookStoryTitleSource.firstLine,
        customTitle: _customTitle.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          AppSpacing.base + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.workflow.builtIn ? 'Edit workflow' : 'Workflow',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publish to Page'),
              value: _feed,
              onChanged: (value) => setState(() => _feed = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publish a Story too'),
              subtitle: const Text(
                'Stories use a 9:16 image with a short title',
              ),
              value: _story,
              onChanged: (value) => setState(() => _story = value),
            ),
            if (_story) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use a custom Story title'),
                value: _customTitleEnabled,
                onChanged: (value) =>
                    setState(() => _customTitleEnabled = value),
              ),
              if (_customTitleEnabled)
                TextField(
                  controller: _customTitle,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Story title',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: 'Save workflow', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
