import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oreamnos/data/models/ai_provider.dart';
import 'package:oreamnos/data/services/provider_api_service.dart';
import 'package:oreamnos/ui/features/settings/view_models/settings_view_model.dart';

/// Dialog to dynamically fetch and select a model for the given provider.
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
  List<String>? _models;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchModels();
  }

  Future<void> _fetchModels() async {
    try {
      final viewModel = context.read<SettingsViewModel>();
      final apiKey = await viewModel.getApiKeyForProvider(widget.provider);
      
      if (apiKey == null || apiKey.isEmpty) {
        throw ProviderApiException('Please configure your API key first.');
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

    return AlertDialog(
      title: Text('${widget.provider.displayName} Models'),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(theme, viewModel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, SettingsViewModel viewModel) {
    if (_isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Fetching available models...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_models == null || _models!.isEmpty) {
      return const Text('No models found.');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _models!.length,
      itemBuilder: (context, index) {
        final model = _models![index];
        final isSelected = viewModel.selectedModel == model;
        
        return ListTile(
          title: Text(model),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
              : null,
          onTap: () {
            viewModel.setSelectedModel(model);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
