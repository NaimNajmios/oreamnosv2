import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/provider_api_service.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Dialog to dynamically fetch, filter, and select a model for the given provider.
class ModelSelectionDialog extends StatefulWidget {
  const ModelSelectionDialog({super.key, required this.provider});

  final AiProvider provider;

  static Future<void> show(BuildContext context, AiProvider provider) {
    return showDialog(
      context: context,
      builder: (context) => ModelSelectionDialog(provider: provider),
    );
  }

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog> {
  final _apiService = ProviderApiService();
  final _searchController = TextEditingController();
  List<String>? _models;
  String? _error;
  bool _isLoading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _fetchModels();
    _searchController.addListener(() {
      setState(() {
        _filter = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    try {
      final viewModel = context.read<SettingsViewModel>();
      final apiKey = await viewModel.getApiKeyForProvider(widget.provider);

      if (apiKey == null || apiKey.isEmpty) {
        throw ProviderApiException('Please configure your API key first in Settings.');
      }

      final models = await _apiService.fetchModels(widget.provider, apiKey);
      if (mounted) {
        setState(() {
          _models = models;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<SettingsViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.provider.displayName} Models',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Select the model configuration for inference.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_isLoading && _error == null && _models != null && _models!.isNotEmpty) ...[
                AppInput(
                  controller: _searchController,
                  hint: 'Search models...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(
                child: _buildContent(theme, viewModel),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, SettingsViewModel viewModel) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              child: KickoffLoadingIndicator(size: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fetching models from ${widget.provider.displayName}...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return ErrorState(
        title: 'Could Not Load Models',
        message: _error!,
        retryLabel: 'Retry Fetch',
        onRetry: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _fetchModels();
        },
      );
    }

    if (_models == null || _models!.isEmpty) {
      return Center(
        child: Text(
          'No models found.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final filtered = _filter.isEmpty
        ? _models!
        : _models!.where((m) => m.toLowerCase().contains(_filter)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No models matching "$_filter"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final model = filtered[index];
        final isSelected = viewModel.selectedModel == model;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Haptics.selectionClick();
              viewModel.setSelectedModel(model);
              Navigator.of(context).pop();
            },
            borderRadius: AppSpacing.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
