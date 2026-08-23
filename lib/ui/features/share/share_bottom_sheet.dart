import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:oreamnos/config/routes/app_router.dart';

class ShareBottomSheet extends StatefulWidget {
  final String initialContent;

  const ShareBottomSheet({super.key, required this.initialContent});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  late String _selectedTone;

  @override
  void initState() {
    super.initState();
    _selectedTone = context.read<SettingsViewModel>().toneMode;
  }

  void _generate() {
    context.read<SettingsViewModel>().setToneMode(_selectedTone);
    context.read<GenerateViewModel>().setPendingInput(widget.initialContent);
    context.read<GenerateViewModel>().generatePost(widget.initialContent);
    Navigator.of(context).pop();
    // Navigate to Generate Screen if not already there
    final goRouter = GoRouter.of(context);
    if (goRouter.routeInformationProvider.value.uri.path != RoutePaths.generate) {
      goRouter.go(RoutePaths.generate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Post',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              widget.initialContent,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Tone',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'formal', label: Text('Formal')),
              ButtonSegment(value: 'casual', label: Text('Casual')),
              ButtonSegment(value: 'humorous', label: Text('Humorous')),
              ButtonSegment(value: 'hype', label: Text('Hype')),
            ],
            selected: {_selectedTone},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedTone = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Now'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
