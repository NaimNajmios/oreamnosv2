import 'package:flutter/material.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_state.dart';

/// Story toggle, title field, and gradient preview.
class FacebookStoryCard extends StatefulWidget {
  const FacebookStoryCard({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onTitleChanged,
  });

  final FacebookComposeState draft;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onTitleChanged;

  @override
  State<FacebookStoryCard> createState() => _FacebookStoryCardState();
}

class _FacebookStoryCardState extends State<FacebookStoryCard> {
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.draft.storyTitle);
  }

  @override
  void didUpdateWidget(covariant FacebookStoryCard oldWidget) {
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
                  constraints: const BoxConstraints(minHeight: 149),
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
