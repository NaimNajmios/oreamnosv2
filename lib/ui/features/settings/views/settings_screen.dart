import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oreamnos/config/constants.dart';
import 'package:oreamnos/config/routes/app_router.dart';
import 'package:oreamnos/config/theme/app_motion.dart';
import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/config/theme/app_theme.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/utils/relative_time.dart';
import 'package:oreamnos/ui/core/widgets/app_card.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/core/widgets/app_switch.dart';
import 'package:oreamnos/ui/core/widgets/section_header.dart';
import 'package:oreamnos/ui/core/widgets/settings_tile.dart';
import 'package:oreamnos/ui/core/widgets/staggered_entrance.dart';
import 'package:oreamnos/domain/models/app_theme_mode.dart';
import 'package:oreamnos/domain/models/vision_mode.dart';
import 'package:oreamnos/ui/features/update/view_models/update_state.dart';
import 'package:oreamnos/ui/features/update/view_models/update_view_model.dart';
import 'package:oreamnos/ui/features/update/widgets/update_dialog.dart';

import '../view_models/settings_view_model.dart';
import 'widgets/api_key_dialog.dart';
import 'widgets/model_selection_dialog.dart';
import 'widgets/provider_selection_dialog.dart';
import 'widgets/reading_size_dialog.dart';
import 'widgets/tavily_api_key_dialog.dart';
import 'widgets/test_connection_tile.dart';
import 'widgets/tone_selection_dialog.dart';

const _curatedThemes = [
  AppThemeMode.system,
  AppThemeMode.light,
  AppThemeMode.dark,
  AppThemeMode.matchday,
];

/// Minimalist Settings hub.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static String toneLabel(String tone) {
    if (tone.isEmpty) return 'Formal';
    return tone[0].toUpperCase() + tone.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final theme = Theme.of(context);

    Future<void> apply(Future<bool> Function() write) async {
      final ok = await write();
      if (ok || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save that setting — try again."),
        ),
      );
    }

    // Avoid flashing default "Setup 0 of 3" values while secure storage and
    // prefs are still loading.
    if (!state.isInitialized) {
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
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.base,
            AppSpacing.xxl,
          ),
          children: const [
            _SettingsSkeletonCard(height: 96),
            SizedBox(height: AppSpacing.base),
            _SettingsSkeletonCard(height: 220),
            SizedBox(height: AppSpacing.base),
            _SettingsSkeletonCard(height: 160),
          ],
        ),
      );
    }

    final hasKey = state.currentApiKey?.isNotEmpty ?? false;
    final verified = state.lastTestOk == true;

    // Auto-select (selectedModel == null) is a valid model choice, so setup
    // only requires a key and a verified connection.
    final setupComplete = hasKey && verified;
    final setupCount = (hasKey ? 1 : 0) + (verified ? 1 : 0);

    final defaultGroup = state.hashtagGroups
        .where((g) => g.isDefault)
        .firstOrNull
        ?.name;

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

    final sections = <Widget>[
      if (!setupComplete)
        _SetupProgressBanner(
          completed: setupCount,
          providerName: state.selectedProvider.displayName,
          nextLabel: !hasKey
              ? 'Add your ${state.selectedProvider.displayName} key to start generating'
              : 'Verify your connection',
          onAction: !hasKey
              ? () => ApiKeyDialog.show(context, state.selectedProvider)
              : () async {
                  final ok = await notifier.testConnection();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? '${state.selectedProvider.displayName} connected successfully'
                            : 'Connection failed — check your API key',
                      ),
                    ),
                  );
                },
        ),
      const SectionHeader(title: 'Appearance'),
      AppCard(
        padding: const EdgeInsets.all(AppSpacing.base),
        borderRadius: AppSpacing.borderRadiusMd,
        child: Row(
          children: [
            for (int i = 0; i < _curatedThemes.length; i++) ...[
              Expanded(
                child: _ThemeOption(
                  mode: _curatedThemes[i],
                  isSelected: state.themeMode == _curatedThemes[i],
                  onTap: () =>
                      apply(() => notifier.setThemeMode(_curatedThemes[i])),
                ),
              ),
              if (i != _curatedThemes.length - 1)
                const SizedBox(width: AppSpacing.sm),
            ],
            const SizedBox(width: AppSpacing.sm),
            _SeeAllThemes(
              current: state.themeMode,
              onSelect: (m) => apply(() => notifier.setThemeMode(m)),
            ),
          ],
        ),
      ),
      const SectionHeader(title: 'AI Provider'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.smart_toy_outlined,
            title: 'Active Provider',
            subtitle: state.lastTestOk == true
                ? '${state.selectedProvider.displayName} · Connected ${relativeTime(state.lastTestedAt)}'
                : state.lastTestOk == false
                ? '${state.selectedProvider.displayName} · Failed — test again'
                : state.selectedProvider.displayName,
            onTap: () => ProviderSelectionDialog.show(context),
          ),
          if (hasKey)
            SettingsTile(
              leadingIcon: Icons.psychology_outlined,
              title: 'Model',
              subtitle: state.selectedModel ?? 'Default (Auto-select)',
              onTap: () =>
                  ModelSelectionDialog.show(context, state.selectedProvider),
            )
          else
            const SettingsTile(
              leadingIcon: Icons.psychology_outlined,
              title: 'Model',
              subtitle: 'Add an API key first',
              trailing: Icon(Icons.lock_outline_rounded, size: 20),
            ),
          SettingsTile(
            leadingIcon: Icons.key_outlined,
            title: 'API Key',
            subtitle: hasKey
                ? '${state.selectedProvider.displayName} · Configured — stored on this device only'
                : 'Not configured — tap to add',
            onTap: () => ApiKeyDialog.show(context, state.selectedProvider),
          ),
          const TestConnectionTile(),
          SettingsTile(
            leadingIcon: Icons.restart_alt_rounded,
            title: 'Reset AI Setup',
            subtitle: 'Removes your API key and model choice',
            onTap: () => _showResetAiSetup(context, ref),
          ),
        ],
      ),
      const SectionHeader(title: 'Search & Context'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.travel_explore_rounded,
            title: 'Web search',
            subtitle: (state.tavilyApiKey?.isNotEmpty ?? false)
                ? 'Tavily · Configured'
                : 'Let AI look up live news & scores (Tavily)',
            onTap: () => TavilyApiKeyDialog.show(context),
          ),
        ],
      ),
      const SectionHeader(title: 'Post Settings'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.tune_rounded,
            title: 'Writing voice',
            subtitle: toneLabel(state.toneMode),
            onTap: () => ToneSelectionDialog.show(context),
          ),
          SettingsTile(
            leadingIcon: Icons.history_toggle_off_rounded,
            title: 'Remember options',
            subtitle:
                'Persist last-used length & research mode across sessions',
            trailing: AppSwitch(
              value: state.persistGenerationOptions,
              onChanged: (value) =>
                  apply(() => notifier.setPersistGenerationOptions(value)),
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.sports_soccer_rounded,
            title: 'Supporter voice',
            subtitle: state.isFanModeEnabled
                ? (state.fanClubName.trim().isEmpty
                      ? 'Fan Mode on — add your club below'
                      : 'Write as a ${state.fanClubName.trim()} supporter')
                : 'Write as a fan',
            trailing: AppSwitch(
              value: state.isFanModeEnabled,
              onChanged: (value) =>
                  apply(() => notifier.setFanModeEnabled(value)),
            ),
          ),
          if (state.isFanModeEnabled)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: _FanClubField(),
            ),
          SettingsTile(
            leadingIcon: Icons.document_scanner_outlined,
            title: 'On-device vision only',
            subtitle: state.visionMode.name == 'onDeviceOnly'
                ? 'Unlimited, offline — nothing leaves your phone'
                : 'Auto: free cloud vision first, then on-device',
            trailing: AppSwitch(
              value: state.visionMode == VisionMode.onDeviceOnly,
              onChanged: (value) => apply(
                () => notifier.setVisionMode(
                  value ? VisionMode.onDeviceOnly : VisionMode.auto,
                ),
              ),
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.format_size_rounded,
            title: 'Reading text size',
            subtitle:
                '${state.readingTextSize.toStringAsFixed(1)} pt — applies in reading mode',
            onTap: () => ReadingSizeDialog.show(context),
          ),
          SettingsTile(
            leadingIcon: Icons.tag_rounded,
            title: 'Hashtag Manager',
            subtitle: state.hashtagGroups.isEmpty
                ? 'No groups yet — create one'
                : '${state.hashtagGroups.length} groups · Default: ${defaultGroup ?? '—'}',
            onTap: () => context.push(RoutePaths.hashtagManager),
          ),
          SettingsTile(
            leadingIcon: Icons.auto_awesome_outlined,
            title: 'Auto-append Hashtags',
            subtitle: 'Automatically append default group',
            trailing: AppSwitch(
              value: state.autoAppendHashtags,
              onChanged: (value) =>
                  apply(() => notifier.setAutoAppendHashtags(value)),
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.edit_note_rounded,
            title: 'Manage Refinement Pills',
            subtitle: state.customPills.isEmpty
                ? 'No pills yet — e.g. "Shorter"'
                : '${state.customPills.length} custom pills',
            onTap: () => context.push(RoutePaths.pillManager),
          ),
        ],
      ),
      const SectionHeader(title: 'Usage & Analytics'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.analytics_outlined,
            title: 'Usage Statistics',
            subtitle: 'View token usage & latency',
            onTap: () => context.go(RoutePaths.usage),
          ),
          SettingsTile(
            leadingIcon: Icons.menu_open_rounded,
            title: 'Session History',
            subtitle: 'Tap to review past conversations',
            onTap: () => context.go(RoutePaths.sessionHistory),
          ),
        ],
      ),
      const SectionHeader(title: 'Home screen widgets'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.widgets_outlined,
            title: 'Home screen widgets',
            subtitle:
                'Five widgets available — tap to see what fits your device',
            onTap: () => context.push(RoutePaths.widgets),
          ),
        ],
      ),
      const SectionHeader(title: 'Data'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.delete_sweep_rounded,
            title: 'Clear Local Data',
            subtitle: 'Logs, usage history, Facebook drafts & cached images — settings are kept',
            onTap: () => _showClearLocalData(context, ref),
          ),
        ],
      ),
      const SectionHeader(title: 'Legal'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.description_rounded,
            title: 'Privacy Policy',
            subtitle: _legalSubtitle(AppConstants.privacyPolicyUrl),
            onTap: () => _launchLegal(
              context,
              AppConstants.privacyPolicyUrl,
              'Privacy Policy',
            ),
          ),
          SettingsTile(
            leadingIcon: Icons.gavel_rounded,
            title: 'Terms of Service',
            subtitle: _legalSubtitle(AppConstants.termsOfServiceUrl),
            onTap: () => _launchLegal(
              context,
              AppConstants.termsOfServiceUrl,
              'Terms of Service',
            ),
          ),
        ],
      ),
      const SectionHeader(title: 'Advanced'),
      sectionCard(
        children: [
          SettingsTile(
            leadingIcon: Icons.bug_report_outlined,
            title: 'Debug Logs',
            subtitle: 'View and copy internal system logs',
            onTap: () => context.push(RoutePaths.debugLogs),
          ),
        ],
      ),
      const SectionHeader(title: 'About'),
      sectionCard(
        children: [
          const _UpdateCheckTile(),
          SettingsTile(
            leadingIcon: Icons.ios_share_rounded,
            title: 'Export Settings',
            subtitle: 'Share a JSON backup of your settings',
            onTap: () => _exportSettings(context, ref),
          ),
          SettingsTile(
            leadingIcon: Icons.file_download_rounded,
            title: 'Import Settings',
            subtitle: 'Apply settings from a JSON backup',
            onTap: () => _importSettings(context, ref),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xl,
            ),
            itemCount: sections.length,
            separatorBuilder: (context, index) {
              if (sections[index] is SectionHeader) {
                return const SizedBox(height: AppSpacing.sm);
              }
              return const SizedBox(height: AppSpacing.xl);
            },
            itemBuilder: (context, index) {
              return StaggeredEntranceItem(
                index: index,
                delay: const Duration(milliseconds: 60),
                yOffset: 12,
                child: sections[index],
              );
            },
          ),
        ),
      ),
    );
  }

  /// "Reset AI Setup" — clears the active provider's key and model choice.
  Future<void> _showResetAiSetup(BuildContext context, WidgetRef ref) async {
    final provider = ref.read(settingsViewModelProvider).selectedProvider;
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset AI Setup'),
        content: const Text(
          'Remove the current API key and model choice? '
          'You will set them up again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (result != true) return;
    Haptics.heavyImpact();
    final notifier = ref.read(settingsViewModelProvider.notifier);
    await notifier.clearApiKey(provider);
    await notifier.clearSelectedModel();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('AI setup reset')));
  }

  /// "Clear Local Data" — destructive confirm, then clears logs/usage data.
  Future<void> _showClearLocalData(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'Logs, usage history, Facebook drafts and cached images will be '
          'deleted. Settings and API keys are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (result != true) return;
    Haptics.heavyImpact();
    await ref.read(settingsViewModelProvider.notifier).clearLocalData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Local data cleared')));
  }

  /// "Export Settings" — share a JSON backup of the app settings.
  Future<void> _exportSettings(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsViewModelProvider.notifier);
    try {
      final json = jsonEncode(await notifier.exportSettings());
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/oreamnos-settings-'
        '${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: 'Oreamnos settings backup',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't export your settings")),
      );
    }
  }

  /// "Import Settings" — apply settings from JSON pasted into the clipboard.
  Future<void> _importSettings(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsViewModelProvider.notifier);
    String text;
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      text = clipboardData?.text ?? '';
    } catch (_) {
      text = '';
    }
    if (text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to import from the clipboard')),
      );
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      await notifier.importSettings(decoded.cast<String, Object?>());
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste valid settings JSON to import.')),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings imported')));
  }

  static String _legalSubtitle(String url) => url.isEmpty ? 'Not set yet' : url;

  /// Opens a Legal URL, with a snackbar when it is not configured.
  Future<void> _launchLegal(
    BuildContext context,
    String url,
    String label,
  ) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label URL is not set yet.')));
      return;
    }
    try {
      final opened = await launchUrl(Uri.parse(url));
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open that page")),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open that page")),
        );
      }
    }
  }
}

class _SetupProgressBanner extends StatelessWidget {
  const _SetupProgressBanner({
    required this.completed,
    required this.providerName,
    required this.nextLabel,
    this.onAction,
  });

  final int completed;
  final String providerName;
  final String nextLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      borderColor: theme.colorScheme.primary,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  Icons.rocket_launch_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup $completed of 3',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(nextLabel, style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusPill,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: completed / 3),
              duration: AppMotion.count,
              curve: AppMotion.curveCount,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Haptics.lightImpact();
                  onAction!.call();
                },
                child: Text(
                  completed == 0 ? 'Add $providerName key' : 'Continue setup',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewFor(mode, context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${mode.label} theme',
      child: InkWell(
        onTap: () {
          Haptics.lightImpact();
          onTap();
        },
        borderRadius: AppSpacing.borderRadiusMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: mode == AppThemeMode.system
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_rounded
                              : Icons.settings_suggest_rounded,
                          size: 20,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [preview.$1, preview.$2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: Colors.white,
                              )
                            : null,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              mode.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// (surface, accent) sampled from the real ThemeData builders.
  static (Color, Color) _previewFor(AppThemeMode mode, BuildContext context) {
    switch (mode) {
      case AppThemeMode.light:
        final s = AppTheme.light().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.dark:
        final s = AppTheme.dark().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.deepBlue:
        final s = AppTheme.deepBlue().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.midnightNoir:
        final s = AppTheme.midnightNoir().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.solarizedLight:
        final s = AppTheme.solarizedLight().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.cyberpunk:
        final s = AppTheme.cyberpunk().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.matchday:
        final s = AppTheme.matchday().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.forest:
        final s = AppTheme.forest().colorScheme;
        return (s.surface, s.primary);
      case AppThemeMode.system:
        final s = Theme.of(context).colorScheme;
        return (s.surface, s.primary);
    }
  }
}

class _SeeAllThemes extends StatelessWidget {
  const _SeeAllThemes({required this.current, required this.onSelect});

  final AppThemeMode current;
  final ValueChanged<AppThemeMode> onSelect;

  static const _descriptions = {
    AppThemeMode.system: 'Follows your phone',
    AppThemeMode.light: 'Clean daylight',
    AppThemeMode.dark: 'Easy on the eyes',
    AppThemeMode.deepBlue: 'Navy night',
    AppThemeMode.midnightNoir: 'Pure-black OLED',
    AppThemeMode.solarizedLight: 'Warm paper',
    AppThemeMode.cyberpunk: 'Neon arcade',
    AppThemeMode.matchday: 'Energetic red',
    AppThemeMode.forest: 'Deep green night',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'All themes',
      child: InkWell(
        onTap: () {
          Haptics.lightImpact();
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All themes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pick the look for the whole app.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: AppThemeMode.values.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final mode = AppThemeMode.values[i];
                          final selected = mode == current;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            leading: _MiniSwatch(mode: mode),
                            title: Text(
                              mode.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              _descriptions[mode] ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: selected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              Haptics.selectionClick();
                              onSelect(mode);
                              Navigator.of(sheetContext).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'All',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSwatch extends StatelessWidget {
  const _MiniSwatch({required this.mode});

  final AppThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = _ThemeOption._previewFor(mode, context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [colors.$1, colors.$2]),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: mode == AppThemeMode.system
          ? Icon(
              Icons.settings_suggest_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : null,
    );
  }
}

class _FanClubField extends ConsumerStatefulWidget {
  const _FanClubField();

  @override
  ConsumerState<_FanClubField> createState() => _FanClubFieldState();
}

class _FanClubFieldState extends ConsumerState<_FanClubField> {
  late final TextEditingController _controller;
  late final SettingsNotifier _notifier;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(settingsViewModelProvider.notifier);
    _controller = TextEditingController(
      text: ref.read(settingsViewModelProvider).fanClubName,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Flush an in-flight edit instead of dropping it when the field unmounts.
    unawaited(_notifier.setFanClubName(_controller.text.trim()));
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_notifier.setFanClubName(value.trim()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final fanEnabled = ref.watch(
      settingsViewModelProvider.select((s) => s.isFanModeEnabled),
    );
    final savedName = ref.watch(
      settingsViewModelProvider.select((s) => s.fanClubName),
    );
    final showError = fanEnabled && savedName.trim().isEmpty;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInput(
            controller: _controller,
            label: 'Club you support',
            hint: 'e.g. Arsenal',
            textInputAction: TextInputAction.done,
            onChanged: _onChanged,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Enter your club — required for supporter voice',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// Neutral placeholder shown while Settings loads from prefs/secure storage.
class _SettingsSkeletonCard extends StatelessWidget {
  const _SettingsSkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),
    );
  }
}

/// About-tile that runs a manual GitHub release lookup.
class _UpdateCheckTile extends ConsumerWidget {
  const _UpdateCheckTile();

  Future<void> _check(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(updateViewModelProvider.notifier);
    await notifier.checkForUpdates(manual: true);
    if (!context.mounted) return;

    final state = ref.read(updateViewModelProvider);
    switch (state.status) {
      case UpdateStatus.available:
        final release = state.latestRelease;
        if (release != null) {
          await showUpdateDialog(
            context,
            ref,
            release: release,
            currentVersion: state.currentVersion,
          );
        }
        break;
      case UpdateStatus.upToDate:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You're up to date — ${state.currentVersion}."),
          ),
        );
        break;
      case UpdateStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'The update check failed.'),
          ),
        );
        break;
      case UpdateStatus.idle:
      case UpdateStatus.checking:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateViewModelProvider);
    final label = state.versionLabel;

    return SettingsTile(
      leadingIcon: Icons.system_update_alt_rounded,
      title: 'Check for updates',
      subtitle: label.isEmpty ? 'Tap to check GitHub Releases' : label,
      trailing: state.isChecking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: state.isChecking ? null : () => _check(context, ref),
    );
  }
}
