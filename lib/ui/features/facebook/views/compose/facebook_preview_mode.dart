import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';
import 'package:oreamnos/ui/features/facebook/widgets/compose/facebook_compose_widgets.dart';

/// Light/dark, visitor-style feed preview.
class FacebookPreviewMode extends StatefulWidget {
  const FacebookPreviewMode({
    super.key,
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
  State<FacebookPreviewMode> createState() => _FacebookPreviewModeState();
}

class _FacebookPreviewModeState extends State<FacebookPreviewMode> {
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
