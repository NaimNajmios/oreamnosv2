import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../view_models/settings_view_model.dart';
import 'widgets/api_key_dialog.dart';
import 'widgets/model_selection_dialog.dart';
import 'widgets/provider_selection_dialog.dart';
import 'widgets/theme_selection_dialog.dart';
import 'widgets/tone_selection_dialog.dart';

/// Settings screen for configuring AI providers, post settings, and appearance.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'AI Provider'),
          const SizedBox(height: 8),
          _buildTile(
            context,
            icon: Icons.smart_toy_outlined,
            title: 'Active Provider',
            subtitle: viewModel.selectedProvider.displayName,
            onTap: () => ProviderSelectionDialog.show(context),
          ),
          _buildTile(
            context,
            icon: Icons.model_training,
            title: 'Model',
            subtitle: viewModel.selectedModel ?? 'Default (Auto-select)',
            onTap: () => ModelSelectionDialog.show(context, viewModel.selectedProvider),
          ),
          _buildTile(
            context,
            icon: Icons.vpn_key_outlined,
            title: 'API Key',
            subtitle: (viewModel.currentApiKey?.isNotEmpty ?? false)
                ? '•••••••• (Configured)'
                : 'Not configured',
            onTap: () => ApiKeyDialog.show(context, viewModel.selectedProvider),
          ),
          const Divider(height: 32),

          _buildSectionHeader(context, 'Post Settings'),
          const SizedBox(height: 8),
          _buildTile(
            context,
            icon: Icons.tune,
            title: 'Tone',
            subtitle: viewModel.toneMode[0].toUpperCase() + viewModel.toneMode.substring(1),
            onTap: () => ToneSelectionDialog.show(context),
          ),
          _buildTile(
            context,
            icon: Icons.tag,
            title: 'Hashtag Manager',
            subtitle: '${viewModel.hashtagGroups.length} groups',
            onTap: () => context.push(RoutePaths.hashtagManager),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-append Hashtags'),
            subtitle: Text(
              'Automatically append hashtags to generated posts',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
            value: viewModel.autoAppendHashtags,
            activeTrackColor: Theme.of(context).colorScheme.primary.withAlpha(128),
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) => viewModel.setAutoAppendHashtags(value),
          ),
          _buildTile(
            context,
            icon: Icons.edit_note,
            title: 'Manage Refinement Pills',
            subtitle: '${viewModel.customPills.length} custom pills',
            onTap: () => context.push(RoutePaths.pillManager),
          ),
          const Divider(height: 32),

          _buildSectionHeader(context, 'Usage & Analytics'),
          _buildTile(
            context,
            icon: Icons.bar_chart,
            title: 'Usage Statistics',
            subtitle: 'View token usage and latency',
            onTap: () => context.push(RoutePaths.usage),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 8),
          _buildTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: viewModel.themeMode.label,
            onTap: () => ThemeSelectionDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(153),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withAlpha(102),
      ),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
