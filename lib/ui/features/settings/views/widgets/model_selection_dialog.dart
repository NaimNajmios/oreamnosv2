import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oreamnos/config/theme/app_spacing.dart';
import 'package:oreamnos/data/models/ai_model.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

import '../../view_models/settings_state.dart';

import 'package:oreamnos/data/services/provider_api_service.dart';
import 'package:oreamnos/ui/core/utils/haptics.dart';
import 'package:oreamnos/ui/core/widgets/app_input.dart';
import 'package:oreamnos/ui/core/widgets/error_state.dart';
import 'package:oreamnos/ui/core/widgets/kickoff_loading_indicator.dart';
import 'package:oreamnos/ui/core/widgets/skeleton_loader.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

import 'api_key_dialog.dart';

/// Dialog to dynamically fetch, filter, and select a model for the given provider.
class ModelSelectionDialog extends ConsumerStatefulWidget {
  const ModelSelectionDialog({super.key, required this.provider});

  final AiProvider provider;

  static Future<void> show(BuildContext context, AiProvider provider) {
    return showDialog(
      context: context,
      builder: (context) => ModelSelectionDialog(provider: provider),
    );
  }

  @override
  ConsumerState<ModelSelectionDialog> createState() =>
      _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends ConsumerState<ModelSelectionDialog> {
  final _apiService = ProviderApiService();
  final _searchController = TextEditingController();
  List<AiModel>? _models;
  String? _error;
  bool _isLoading = true;
  bool _needsKey = false;
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
      final viewModel = ref.read(settingsViewModelProvider.notifier);
      final apiKey = await viewModel.getApiKeyForProvider(widget.provider);

      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          setState(() {
            _needsKey = true;
            _isLoading = false;
          });
        }
        return;
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
    final state = ref.watch(settingsViewModelProvider);

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_isLoading &&
                  _error == null &&
                  _models != null &&
                  _models!.isNotEmpty) ...[
                AppInput(
                  controller: _searchController,
                  hint: 'Search models...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(child: _buildContent(theme, state)),
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

  Widget _buildContent(ThemeData theme, SettingsState state) {
    if (_needsKey) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.key_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'API key required',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add your ${widget.provider.displayName} key to load models.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ApiKeyDialog.show(context, widget.provider);
              },
              child: const Text('Add key'),
            ),
          ],
        ),
      );
    }
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader.textLine(context),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader.textLine(context, width: 220),
          const SizedBox(height: AppSpacing.base),
          const Center(child: KickoffLoadingIndicator(size: 24)),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Fetching models from ${widget.provider.displayName}...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
            _needsKey = false;
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
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final filtered = _filter.isEmpty
        ? _models!
        : _models!.where((m) => m.id.toLowerCase().contains(_filter)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No models matching "$_filter"',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final model = filtered[index];
        final isSelected = state.selectedModel == model.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Haptics.selectionClick();
              ref
                  .read(settingsViewModelProvider.notifier)
                  .setSelectedModel(model.id);
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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            model.id,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (model.isFree) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: Text(
                              'FREE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
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
