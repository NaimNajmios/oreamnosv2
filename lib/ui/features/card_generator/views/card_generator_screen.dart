import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oreamnos/ui/features/card_generator/view_models/card_generator_view_model.dart';
import 'package:oreamnos/ui/features/card_generator/widgets/card_canvas.dart';
import 'package:oreamnos/data/models/ai_provider.dart';

class CardGeneratorScreen extends StatefulWidget {
  final String generatedText;
  final AiProvider provider;
  final String apiKey;
  final String modelId;

  const CardGeneratorScreen({
    super.key,
    required this.generatedText,
    required this.provider,
    required this.apiKey,
    required this.modelId,
  });

  @override
  State<CardGeneratorScreen> createState() => _CardGeneratorScreenState();
}

class _CardGeneratorScreenState extends State<CardGeneratorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardGeneratorViewModel>().extractData(
        widget.generatedText, 
        widget.provider, 
        widget.apiKey, 
        widget.modelId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CardGeneratorViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Generator'),
        actions: [
          if (viewModel.cardData != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => viewModel.shareCard(_boundaryKey),
              tooltip: 'Share',
            ),
          if (viewModel.cardData != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () async {
                final success = await viewModel.saveToGallery(_boundaryKey);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Saved to gallery' : 'Failed to save'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              tooltip: 'Save to Gallery',
            ),
        ],
      ),
      body: viewModel.isExtracting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Extracting key points from text...'),
                ],
              ),
            )
          : viewModel.extractionError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: ${viewModel.extractionError}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : viewModel.cardData != null
                  ? Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: RepaintBoundary(
                                key: _boundaryKey,
                                child: CardCanvas(
                                  cardData: viewModel.cardData!,
                                  template: viewModel.selectedTemplate,
                                  background: viewModel.selectedBackground,
                                  font: viewModel.selectedFont,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildDesignStudio(context, viewModel),
                      ],
                    )
                  : const Center(child: Text('No data extracted.')),
    );
  }

  Widget _buildDesignStudio(BuildContext context, CardGeneratorViewModel viewModel) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Template',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: CardTemplate.values.map((t) {
                  final isSelected = viewModel.selectedTemplate == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) => viewModel.setTemplate(t),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Background',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: CardBackground.values.map((b) {
                  final isSelected = viewModel.selectedBackground == b;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(b.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) => viewModel.setBackground(b),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Typography',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: AppFont.values.map((f) {
                  final isSelected = viewModel.selectedFont == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) => viewModel.setFont(f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

