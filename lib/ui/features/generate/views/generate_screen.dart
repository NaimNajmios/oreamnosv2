import 'package:flutter/material.dart';

import 'package:provider/provider.dart';


import '../view_models/generate_view_model.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_copy_button.dart';
import '../../../core/widgets/typewriter_markdown.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<GenerateViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oreamnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to session history
            },
            tooltip: 'Session History',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildContentArea(theme, viewModel),
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _controller,
                hint: 'Enter football news URL or paste content...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Generate Post',
                isLoading: viewModel.state == GenerateState.generating,
                icon: Icons.auto_awesome,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  viewModel.generatePost(_controller.text);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(ThemeData theme, GenerateViewModel viewModel) {
    if (viewModel.state == GenerateState.idle) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Oreamnos',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'AI Assisted Social Media Curator',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (viewModel.state == GenerateState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Failed to generate',
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.errorMessage ?? 'Unknown error',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.state == GenerateState.generating) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Success state
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated Post',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppCopyButton(textToCopy: viewModel.generatedContent ?? ''),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: TypewriterMarkdown(
                  data: viewModel.generatedContent ?? '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
