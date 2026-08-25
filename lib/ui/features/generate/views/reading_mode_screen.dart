import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/curated_post_sections.dart';
import 'package:oreamnos/ui/core/widgets/source_attribution_card.dart';
import 'package:oreamnos/ui/core/widgets/typewriter_markdown.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Full-screen distraction-free reading mode — now with drag-dismiss + persistent textSize.
class ReadingModeScreen extends StatefulWidget {
  const ReadingModeScreen({
    super.key,
    required this.content,
    this.curatedPost,
  });

  final String content;
  final CuratedPost? curatedPost;

  @override
  State<ReadingModeScreen> createState() => _ReadingModeScreenState();
}

class _ReadingModeScreenState extends State<ReadingModeScreen> {
  double _dragOffset = 0;
  double _opacity = 1.0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset < 0) _dragOffset = 0;
      _opacity = (1 - (_dragOffset / 300)).clamp(0.0, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset > 120) {
      Haptics.lightImpact();
      context.pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _opacity = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsViewModel>();
    final textSize = settings.readingTextSize;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: _opacity),
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Opacity(
            opacity: _opacity,
            child: SafeArea(
              child: Stack(
                children: [
                  // Centered Reading Column — scaled by persistent textSize (12-24, default 16)
                  Center(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textSize / 16.0)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.huge + AppSpacing.base,
                            AppSpacing.xl,
                            100,
                          ),
                          child: widget.curatedPost != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TitleBlock(title: widget.curatedPost!.title),
                                    BodyBlock(bodyMarkdown: widget.curatedPost!.bodyMarkdown),
                                    if (widget.curatedPost!.hashtags.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.base),
                                      HashtagChips(hashtags: widget.curatedPost!.hashtags),
                                    ],
                                    if (!widget.curatedPost!.source.isEmpty) ...[
                                      const SizedBox(height: AppSpacing.base),
                                      SourceAttributionCard(source: widget.curatedPost!.source),
                                    ],
                                  ],
                                )
                              : TypewriterMarkdown(data: widget.content),
                        ),
                      ),
                    ),
                  ),
                  // Text Size Controls (persistent 12-24)
                  Positioned(
                    top: AppSpacing.base,
                    left: AppSpacing.base,
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      borderRadius: AppSpacing.borderRadiusPill,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.text_decrease_rounded, size: 18),
                            onPressed: () {
                              Haptics.selectionClick();
                              final next = (textSize - 1).clamp(12.0, 24.0);
                              context.read<SettingsViewModel>().setReadingTextSize(next);
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          Text('${textSize.toInt()}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.text_increase_rounded, size: 18),
                            onPressed: () {
                              Haptics.selectionClick();
                              final next = (textSize + 1).clamp(12.0, 24.0);
                              context.read<SettingsViewModel>().setReadingTextSize(next);
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Top Floating Close Button
                  Positioned(
                    top: AppSpacing.base,
                    right: AppSpacing.base,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Haptics.lightImpact();
                          context.pop();
                        },
                        borderRadius: AppSpacing.borderRadiusPill,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.outline, width: 1),
                            boxShadow: AppSpacing.softShadow(theme.brightness == Brightness.dark),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom Floating Actions (Copy & Share)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.xl,
                    child: Center(
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        borderRadius: AppSpacing.borderRadiusPill,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: widget.content));
                                Haptics.mediumImpact();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Copied to clipboard'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusSm),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.content_copy_rounded, size: 18),
                              label: const Text('Copy'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: theme.colorScheme.outline,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Haptics.lightImpact();
                                // ignore: deprecated_member_use
                                Share.share(widget.content);
                              },
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Share'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
