import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_colors.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/section_header.dart';
import 'package:oreamnos/ui/core/widgets/settings_tile.dart';
import '../view_models/settings_view_model.dart';
import 'widgets/api_key_dialog.dart';
import 'widgets/model_selection_dialog.dart';
import 'widgets/provider_selection_dialog.dart';
import 'widgets/theme_selection_dialog.dart';
import 'widgets/tone_selection_dialog.dart';

/// Serene Editorial Settings hub with grouped card sections.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? AppColors.darkTeal : AppColors.lightTeal;
    final tealSoft = isDark ? AppColors.darkTealSoft : AppColors.lightTealSoft;
    final amber = isDark ? AppColors.darkAmber : AppColors.lightAmber;
    final amberSoft = isDark ? AppColors.darkAmberSoft : AppColors.lightAmberSoft;
    final violet = isDark ? AppColors.darkViolet : AppColors.lightViolet;
    final violetSoft = isDark ? AppColors.darkVioletSoft : AppColors.lightVioletSoft;
    final emerald = isDark ? AppColors.darkEmerald : AppColors.lightEmerald;
    final emeraldSoft = isDark ? AppColors.darkEmeraldSoft : AppColors.lightEmeraldSoft;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.base,
            ),
            children: [
              // 1. AI Provider Section
              const SectionHeader(title: 'AI Provider'),
              AppCard(
                accentColor: teal,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      leadingIcon: Icons.smart_toy_outlined,
                      title: 'Active Provider',
                      subtitle: viewModel.selectedProvider.displayName,
                      iconBackgroundColor: tealSoft.withValues(alpha: 0.35),
                      iconColor: teal,
                      onTap: () => ProviderSelectionDialog.show(context),
                    ),
                    const Divider(indent: 56),
                    SettingsTile(
                      leadingIcon: Icons.psychology_outlined,
                      title: 'Model',
                      subtitle: viewModel.selectedModel ?? 'Default (Auto-select)',
                      iconBackgroundColor: tealSoft.withValues(alpha: 0.28),
                      iconColor: teal,
                      onTap: () => ModelSelectionDialog.show(context, viewModel.selectedProvider),
                    ),
                    const Divider(indent: 56),
                    SettingsTile(
                      leadingIcon: Icons.key_outlined,
                      title: 'API Key',
                      subtitle: (viewModel.currentApiKey?.isNotEmpty ?? false)
                          ? '•••••••• (Configured)'
                          : 'Not configured',
                      iconBackgroundColor: amberSoft.withValues(alpha: 0.35),
                      iconColor: amber,
                      onTap: () => ApiKeyDialog.show(context, viewModel.selectedProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Post Settings Section
              const SectionHeader(title: 'Post Settings'),
              AppCard(
                accentColor: amber,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      leadingIcon: Icons.tune_rounded,
                      title: 'Tone',
                      subtitle: viewModel.toneMode[0].toUpperCase() + viewModel.toneMode.substring(1),
                      iconBackgroundColor: amberSoft.withValues(alpha: 0.35),
                      iconColor: amber,
                      onTap: () => ToneSelectionDialog.show(context),
                    ),
                    const Divider(indent: 56),
                    SettingsTile(
                      leadingIcon: Icons.tag_rounded,
                      title: 'Hashtag Manager',
                      subtitle: '${viewModel.hashtagGroups.length} groups',
                      iconBackgroundColor: emeraldSoft.withValues(alpha: 0.35),
                      iconColor: emerald,
                      onTap: () => context.push(RoutePaths.hashtagManager),
                    ),
                    const Divider(indent: 56),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: amberSoft.withValues(alpha: 0.35),
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: Icon(
                              Icons.auto_awesome_outlined,
                              size: 18,
                              color: amber,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-append Hashtags',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Automatically append default group to generated posts',
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                    const Divider(indent: 56),
                    SettingsTile(
                      leadingIcon: Icons.edit_note_rounded,
                      title: 'Manage Refinement Pills',
                      subtitle: '${viewModel.customPills.length} custom pills',
                      iconBackgroundColor: violetSoft.withValues(alpha: 0.35),
                      iconColor: violet,
                      onTap: () => context.push(RoutePaths.pillManager),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Usage & Analytics Section
              const SectionHeader(title: 'Usage & Analytics'),
              AppCard(
                accentColor: violet,
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  leadingIcon: Icons.analytics_outlined,
                  title: 'Usage Statistics',
                  subtitle: 'View token usage, latency & recent requests',
                  iconBackgroundColor: violetSoft.withValues(alpha: 0.35),
                  iconColor: violet,
                  onTap: () => context.push(RoutePaths.usage),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Appearance Section
              const SectionHeader(title: 'Appearance'),
              AppCard(
                accentColor: emerald,
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  leadingIcon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: viewModel.themeMode.label,
                  iconBackgroundColor: emeraldSoft.withValues(alpha: 0.35),
                  iconColor: emerald,
                  onTap: () => ThemeSelectionDialog.show(context),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5. Advanced Section
              const SectionHeader(title: 'Advanced'),
              AppCard(
                accentColor: AppColors.error,
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  leadingIcon: Icons.bug_report_outlined,
                  title: 'Debug Logs',
                  subtitle: 'View and copy internal system logs',
                  iconBackgroundColor: AppColors.errorSoft.withValues(alpha: 0.5),
                  iconColor: AppColors.error,
                  onTap: () => context.push(RoutePaths.debugLogs),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}


