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
  bool? _lastResult;

  Future<void> _test() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _lastResult = null;
    });
    Haptics.selectionClick();
    try {
      final settings = ref.read(settingsViewModelProvider);
      final provider = settings.selectedProvider;
      final apiKey = await ref
          .read(settingsViewModelProvider.notifier)
          .getApiKeyForProvider(provider);
      final ok = await getIt<ProviderApiService>().testConnection(
        provider,
        apiKey ?? '',
      );
      if (!mounted) return;
      setState(() => _lastResult = ok);
      Haptics.success();
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
      if (!mounted) return;
      setState(() => _lastResult = false);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _testing
        ? 'Testing…'
        : _lastResult == true
        ? 'Connected ✓'
        : _lastResult == false
        ? 'Failed — tap to retry'
        : 'Verify your API key works';
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
          : _lastResult == true
          ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600)
          : _lastResult == false
          ? Icon(Icons.error_rounded, color: theme.colorScheme.error)
          : null,
      onTap: _test,
    );
  }
}
