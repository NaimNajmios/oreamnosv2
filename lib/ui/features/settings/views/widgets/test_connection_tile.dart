import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/provider_api_service.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/settings_tile.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Test Connection tile (Android `testConnectionButton` parity).
/// Probes the selected provider with the stored API key and reports
/// success/failure inline without leaving Settings.
class TestConnectionTile extends ConsumerStatefulWidget {
  const TestConnectionTile({super.key});

  @override
  ConsumerState<TestConnectionTile> createState() => _TestConnectionTileState();
}

class _TestConnectionTileState extends ConsumerState<TestConnectionTile> {
  bool _testing = false;

  static String _relativeTime(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _test() async {
    if (_testing) return;
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final provider = ref.read(settingsViewModelProvider).selectedProvider;
    final apiKey = await notifier.getApiKeyForProvider(provider);
    if ((apiKey ?? '').isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add an API key first, then test the connection'),
        ),
      );
      return;
    }
    setState(() => _testing = true);
    Haptics.selectionClick();
    try {
      final ok = await getIt<ProviderApiService>().testConnection(
        provider,
        apiKey ?? '',
      );
      await notifier.setLastTestResult(ok);
      if (!mounted) return;
      if (ok) {
        Haptics.success();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${provider.displayName} connected successfully'
                : '${provider.displayName} connection failed — check your API key',
          ),
        ),
      );
    } catch (_) {
      await notifier.setLastTestResult(false);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsViewModelProvider);
    final lastResult = settings.lastTestOk;
    final subtitle = _testing
        ? 'Testing…'
        : lastResult == true
        ? 'Connected · ${_relativeTime(settings.lastTestedAt)}'
        : lastResult == false
        ? 'Failed — tap to retry'
        : 'Check connection';
    final successColor = theme.brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;
    return SettingsTile(
      leadingIcon: Icons.wifi_find_rounded,
      title: 'Test Connection',
      subtitle: subtitle,
      trailing: _testing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : lastResult == true
          ? Icon(Icons.check_circle_rounded, color: successColor)
          : lastResult == false
          ? Icon(Icons.error_rounded, color: theme.colorScheme.error)
          : null,
      onTap: _test,
    );
  }
}
