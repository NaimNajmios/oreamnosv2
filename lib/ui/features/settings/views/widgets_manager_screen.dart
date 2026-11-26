import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/services/home_widget_service.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';
import 'package:oreamnos/ui/core/widgets/section_header.dart';
import 'package:oreamnos/ui/core/widgets/settings_tile.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Widgets page — pin home-screen widgets and toggle the caption preview.
/// The widgets themselves are read-only: taps open Oreamnos, never post.
class WidgetsManagerScreen extends ConsumerStatefulWidget {
  const WidgetsManagerScreen({super.key});

  @override
  ConsumerState<WidgetsManagerScreen> createState() =>
      _WidgetsManagerScreenState();
}

class _WidgetsManagerScreenState extends ConsumerState<WidgetsManagerScreen> {
  bool? _supported;

  @override
  void initState() {
    super.initState();
    _resolveSupport();
  }

  Future<void> _resolveSupport() async {
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (mounted) setState(() => _supported = supported == true);
    } catch (_) {
      // Missing plugin (unit tests) or an old launcher: stay hidden.
      if (mounted) setState(() => _supported = false);
    }
  }

  Future<void> _pin(String provider) async {
    try {
      await HomeWidget.requestPinWidget(qualifiedAndroidName: provider);
    } catch (_) {
      // A launcher can refuse; nothing to recover from here.
    }
  }

  static const _widgets = <_WidgetSpec>[
    _WidgetSpec(
      provider: HomeWidgetService.nextUpProvider,
      title: 'Next up',
      purpose: 'When the next scheduled Page post goes live',
      icon: Icons.schedule_rounded,
    ),
    _WidgetSpec(
      provider: HomeWidgetService.quotaProvider,
      title: 'AI quota',
      purpose: "Today's usage for two providers side by side",
      icon: Icons.donut_large_rounded,
    ),
    _WidgetSpec(
      provider: HomeWidgetService.engagementProvider,
      title: 'Engagement',
      purpose: 'How the last post and this week are doing',
      icon: Icons.favorite_border_rounded,
    ),
    _WidgetSpec(
      provider: HomeWidgetService.draftsProvider,
      title: 'Drafts',
      purpose: 'What is half-written, ready to continue',
      icon: Icons.edit_note_rounded,
    ),
    _WidgetSpec(
      provider: HomeWidgetService.bestTimeProvider,
      title: 'Best time',
      purpose: 'When your audience is usually listening',
      icon: Icons.insights_rounded,
    ),
    _WidgetSpec(
      provider: HomeWidgetService.lastPostProvider,
      title: 'Last post',
      purpose: 'How long it has been since your newest published post',
      icon: Icons.access_time_rounded,
    ),
    _WidgetSpec(
      provider: HomeWidgetService.pageReachProvider,
      title: 'Page reach',
      purpose: 'Page views and engagements for your Performance range',
      icon: Icons.bar_chart_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    Widget sectionCard({required List<Widget> children}) {
      return AppCard(
        padding: EdgeInsets.zero,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Divider(height: 1, indent: 68, color: theme.dividerColor),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Widgets',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.xl,
        ),
        children: [
          const SectionHeader(title: 'Home widgets'),
          if (isAndroid)
            sectionCard(
              children: _supported != true
                  ? [
                      const SettingsTile(
                        leadingIcon: Icons.widgets_outlined,
                        title: 'Seven widgets',
                        subtitle:
                            'Long-press your home screen → Widgets → Oreamnos',
                      ),
                    ]
                  : [
                      for (final widget in _widgets)
                        SettingsTile(
                          leadingIcon: widget.icon,
                          title: widget.title,
                          subtitle: widget.purpose,
                          trailing: Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          onTap: () => _pin(widget.provider),
                        ),
                    ],
            ),
          if (!isAndroid)
            AppCard(
              child: Text(
                'Home screen widgets are available on Android.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Post caption'),
          sectionCard(
            children: [
              SettingsTile(
                leadingIcon: Icons.visibility_outlined,
                title: 'Show post caption',
                subtitle: state.showWidgetSnippet
                    ? 'The next post’s text appears on the home screen'
                    : 'Hidden — Page, time and counts still show',
                trailing: AppSwitch(
                  value: state.showWidgetSnippet,
                  onChanged: (value) => notifier.setShowWidgetSnippet(value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.sm,
                  AppSpacing.base,
                  AppSpacing.base,
                ),
                child: Text(
                  'Every widget is read-only and resizable. Taps open Oreamnos — '
                  'nothing posts or changes in the background.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WidgetSpec {
  const _WidgetSpec({
    required this.provider,
    required this.title,
    required this.purpose,
    required this.icon,
  });

  final String provider;
  final String title;
  final String purpose;
  final IconData icon;
}
