import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';
import 'package:oreamnos/ui/core/widgets/section_header.dart';
import 'package:oreamnos/ui/core/widgets/settings_tile.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';

import '../view_models/settings_view_model.dart';
import 'widgets/api_key_dialog.dart';
import 'widgets/model_selection_dialog.dart';
import 'widgets/provider_selection_dialog.dart';
import 'widgets/tavily_api_key_dialog.dart';
import 'widgets/tone_selection_dialog.dart';

/// Minimalist Settings hub.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(settingsViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.colorScheme.outline, height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xl,
            ),
            children: [
              // Theme Toggle
              const SectionHeader(title: 'Appearance'),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    for (int i = 0; i < AppThemeMode.values.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final mode = AppThemeMode.values[i];
                          final isSelected = viewModel.themeMode == mode;

                          Color previewColor;
                          switch (mode) {
                            case AppThemeMode.light:
                              previewColor = Colors.grey.shade300;
                              break;
                            case AppThemeMode.dark:
                              previewColor = Colors.grey.shade900;
                              break;
                            case AppThemeMode.deepBlue:
                              previewColor = const Color(0xFF1E3A8A);
                              break;
                            case AppThemeMode.midnightNoir:
                              previewColor = const Color(0xFF171717);
                              break;
                            case AppThemeMode.solarizedLight:
                              previewColor = const Color(0xFFFDF6E3);
                              break;
                            case AppThemeMode.cyberpunk:
                              previewColor = const Color(0xFFFF003C);
                              break;
                            case AppThemeMode.matchday:
                              previewColor = const Color(0xFFDC2626);
                              break;
                            case AppThemeMode.forest:
                              previewColor = const Color(0xFF2E7D32);
                              break;
                            case AppThemeMode.system:
                              previewColor = theme.colorScheme.primary;
                              break;
                          }

                          return GestureDetector(
                            onTap: () {
                              Haptics.lightImpact();
                              viewModel.setThemeMode(mode);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: previewColor,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                                .withValues(alpha: 0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check_rounded,
                                          color:
                                              previewColor.computeLuminance() >
                                                  0.5
                                              ? Colors.black
                                              : Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  mode.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (i != AppThemeMode.values.length - 1)
                        const SizedBox(width: AppSpacing.md),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // AI Provider Section
              const SectionHeader(title: 'AI Provider'),
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
                onTap: () => ModelSelectionDialog.show(
                  context,
                  viewModel.selectedProvider,
                ),
              ),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.key_outlined,
                title: 'API Key',
                subtitle: (viewModel.currentApiKey?.isNotEmpty ?? false)
                    ? '•••••••• (Configured)'
                    : 'Not configured',
                onTap: () =>
                    ApiKeyDialog.show(context, viewModel.selectedProvider),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.xxl),

              // Tavily Section
              const SectionHeader(title: 'Search & Context'),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.travel_explore_rounded,
                title: 'Tavily Search API',
                subtitle: (viewModel.tavilyApiKey?.isNotEmpty ?? false)
                    ? '•••••••• (Configured)'
                    : 'Configure for AI Research Mode',
                onTap: () => TavilyApiKeyDialog.show(context),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.xxl),

              // Post Settings Section
              const SectionHeader(title: 'Post Settings'),
              const Divider(),
              SettingsTile(
                leadingIcon: Icons.tune_rounded,
                title: 'Tone',
                subtitle:
                    viewModel.toneMode[0].toUpperCase() +
                    viewModel.toneMode.substring(1),
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSwitch(
                      value: viewModel.autoAppendHashtags,
                      onChanged: (value) =>
                          viewModel.setAutoAppendHashtags(value),
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
              const SectionHeader(title: 'Usage & Analytics'),
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
              const SectionHeader(title: 'Advanced'),
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
