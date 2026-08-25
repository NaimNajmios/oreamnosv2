import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/section_header.dart';
import 'package:oreamnos/ui/core/widgets/settings_tile.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';
import 'package:oreamnos/ui/core/widgets/segmented_pill_toggle.dart';
import '../view_models/settings_view_model.dart';
import 'widgets/api_key_dialog.dart';
import 'widgets/model_selection_dialog.dart';
import 'widgets/provider_selection_dialog.dart';
import 'widgets/tone_selection_dialog.dart';

/// Aperture Settings hub.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: theme.textTheme.headlineSmall,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: theme.colorScheme.outline, height: 2),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xl,
            ),
            children: [
              // Theme Toggle
              const SectionHeader(title: 'APPEARANCE'),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: SegmentedPillToggle<AppThemeMode>(
                  items: const [AppThemeMode.system, AppThemeMode.flashMode, AppThemeMode.voidMode],
                  selectedItem: viewModel.themeMode,
                  onChanged: (mode) => viewModel.setThemeMode(mode),
                  itemLabelBuilder: (mode) => mode.label.toUpperCase(),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // AI Provider Section
              const SectionHeader(title: 'AI PROVIDER'),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.smart_toy_outlined,
                title: 'Active Provider',
                subtitle: viewModel.selectedProvider.displayName,
                onTap: () => ProviderSelectionDialog.show(context),
              ),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.psychology_outlined,
                title: 'Model',
                subtitle: viewModel.selectedModel ?? 'Default (Auto-select)',
                onTap: () => ModelSelectionDialog.show(context, viewModel.selectedProvider),
              ),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.key_outlined,
                title: 'API Key',
                subtitle: (viewModel.currentApiKey?.isNotEmpty ?? false)
                    ? '•••••••• (Configured)'
                    : 'Not configured',
                onTap: () => ApiKeyDialog.show(context, viewModel.selectedProvider),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.xxl),

              // Post Settings Section
              const SectionHeader(title: 'POST SETTINGS'),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.tune_rounded,
                title: 'Tone',
                subtitle: viewModel.toneMode[0].toUpperCase() + viewModel.toneMode.substring(1),
                onTap: () => ToneSelectionDialog.show(context),
              ),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.tag_rounded,
                title: 'Hashtag Manager',
                subtitle: '${viewModel.hashtagGroups.length} groups',
                onTap: () => context.push(RoutePaths.hashtagManager),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 24,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-append Hashtags',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Automatically append default group',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: viewModel.autoAppendHashtags,
                      onChanged: (value) => viewModel.setAutoAppendHashtags(value),
                    ),
                  ],
                ),
              ),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.edit_note_rounded,
                title: 'Manage Refinement Pills',
                subtitle: '${viewModel.customPills.length} custom pills',
                onTap: () => context.push(RoutePaths.pillManager),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.xxl),

              // Usage & Analytics Section
              const SectionHeader(title: 'USAGE & ANALYTICS'),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.analytics_outlined,
                title: 'Usage Statistics',
                subtitle: 'View token usage & latency',
                onTap: () => context.push(RoutePaths.usage),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.xxl),

              // Advanced Section
              const SectionHeader(title: 'ADVANCED'),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.bug_report_outlined,
                title: 'Debug Logs',
                subtitle: 'View and copy internal system logs',
                onTap: () => context.push(RoutePaths.debugLogs),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}


