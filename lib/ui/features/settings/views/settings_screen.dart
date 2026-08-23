import 'package:flutter/material.dart';

/// Settings screen.
/// This is a placeholder — will be built out in subsequent migration phases.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Provider section placeholder
          _buildSectionHeader(context, 'AI Provider'),
          const SizedBox(height: 8),
          _buildPlaceholderTile(
            context,
            icon: Icons.smart_toy_outlined,
            title: 'Provider & Model',
            subtitle: 'Configure AI provider and model selection',
          ),
          const Divider(height: 32),

          // Post Settings section placeholder
          _buildSectionHeader(context, 'Post Settings'),
          const SizedBox(height: 8),
          _buildPlaceholderTile(
            context,
            icon: Icons.tune,
            title: 'Tone',
            subtitle: 'Formal or Casual',
          ),
          _buildPlaceholderTile(
            context,
            icon: Icons.tag,
            title: 'Hashtags',
            subtitle: 'Manage default hashtags',
          ),
          const Divider(height: 32),

          // Appearance section placeholder
          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 8),
          _buildPlaceholderTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Light, Dark, or Deep Blue',
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

  Widget _buildPlaceholderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
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
      onTap: () {
        // TODO: Implement in future phases
      },
    );
  }
}
