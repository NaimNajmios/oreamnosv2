import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';

import 'dock_panels/background_panel.dart';
import 'dock_panels/branding_panel.dart';
import 'dock_panels/ratio_panel.dart';
import 'dock_panels/templates_panel.dart';
import 'dock_panels/text_panel.dart';
import 'dock_panels/typography_panel.dart';

enum PicsartPanel { templates, ratio, background, typography, text, branding }

class PicsartToolDock extends ConsumerStatefulWidget {
  const PicsartToolDock({super.key});

  @override
  ConsumerState<PicsartToolDock> createState() => _PicsartToolDockState();
}

class _PicsartToolDockState extends ConsumerState<PicsartToolDock> {
  void _setPanel(String? panel) {
    Haptics.selectionClick();
    ref.read(cardGeneratorViewModelProvider.notifier).setActivePanel(panel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activePanel = ref.watch(
      cardGeneratorViewModelProvider.select((s) => s.activePanel),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: AppMotion.transitionSpec,
              curve: AppMotion.curveTransition,
              child: AnimatedSwitcher(
                duration: AppMotion.transitionSpec,
                switchInCurve: AppMotion.curveTransition,
                switchOutCurve: AppMotion.curveTransition,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(activePanel ?? 'none'),
                  child: activePanel != null
                      ? _buildActivePanel(theme, activePanel)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            _buildMainToolbar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToolbar(ThemeData theme) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _ToolItem(
            icon: Icons.view_carousel_outlined,
            label: 'Templates',
            onTap: () => _setPanel('templates'),
          ),
          _ToolItem(
            icon: Icons.crop_outlined,
            label: 'Ratio',
            onTap: () => _setPanel('ratio'),
          ),
          _ToolItem(
            icon: Icons.image_outlined,
            label: 'Background',
            onTap: () => _setPanel('background'),
          ),
          _ToolItem(
            icon: Icons.text_format_outlined,
            label: 'Typography',
            onTap: () => _setPanel('typography'),
          ),
          _ToolItem(
            icon: Icons.edit_note_outlined,
            label: 'Text',
            onTap: () => _setPanel('text'),
          ),
          _ToolItem(
            icon: Icons.branding_watermark_outlined,
            label: 'Branding',
            onTap: () => _setPanel('branding'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePanel(ThemeData theme, String activePanel) {
    Widget content;
    String title = '';

    switch (activePanel) {
      case 'templates':
        title = 'Templates';
        content = const TemplatesPanel();
        break;
      case 'ratio':
        title = 'Ratio';
        content = const RatioPanel();
        break;
      case 'background':
        title = 'Background';
        content = const BackgroundPanel();
        break;
      case 'typography':
        title = 'Typography';
        content = const TypographyPanel();
        break;
      case 'text':
        title = 'Edit Text';
        content = const TextPanel();
        break;
      case 'branding':
        title = 'Branding & Watermark';
        content = const BrandingPanel();
        break;
      default:
        content = const SizedBox();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel Header
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: () => _setPanel(null),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Panel Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.onSurface),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
