import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/services/export_service.dart';
import '../../../../../domain/models/card_config.dart';
import '../../../../../domain/models/card_data.dart';
import '../../../../../domain/models/carousel_slide.dart';
import '../../../../../domain/models/card_template.dart';
import '../../../../../core/di/injection.dart';
import '../view_models/carousel_composer_view_model.dart';
import '../widgets/renderers/card_canvas_dispatcher.dart';

/// Minimal carousel workspace: up to ten slides, first slide's ratio is the
/// master, and ordered PNGs can be shared to the publishing flow.
class CarouselComposerScreen extends ConsumerStatefulWidget {
  const CarouselComposerScreen({super.key});

  @override
  ConsumerState<CarouselComposerScreen> createState() =>
      _CarouselComposerScreenState();
}

class _CarouselComposerScreenState
    extends ConsumerState<CarouselComposerScreen> {
  final Map<int, GlobalKey> _keys = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carouselComposerProvider);
    final notifier = ref.read(carouselComposerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carousel Studio'),
        actions: [
          DropdownButton<ExportSize>(
            value: state.masterSize,
            underline: const SizedBox.shrink(),
            onChanged: (v) {
              if (v != null) notifier.setMasterSize(v);
            },
            items: ExportSize.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add slide',
            onPressed: () => _showAddSheet(context, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export slides',
            onPressed: state.slides.isEmpty ? null : _export,
          ),
        ],
      ),
      body: state.slides.isEmpty
          ? const Center(
              child: Text('Add up to 10 slides to build a carousel.'),
            )
          : ReorderableListView.builder(
              itemCount: state.slides.length,
              onReorderItem: (oldIndex, newIndex) =>
                  notifier.moveSlide(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final slide = state.slides[index];
                final key = _keys.putIfAbsent(index, GlobalKey.new);
                return ListTile(
                  key: ValueKey('slide-$index'),
                  leading: Container(
                    width: 64,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 380,
                          height: 475,
                          child: RepaintBoundary(
                            key: key,
                            child: CardCanvasDispatcher(
                              cardData: slide.data,
                              config: CardConfig(
                                template: _templateFor(slide.type),
                                exportSize: state.masterSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text('${index + 1}. ${slide.type.name.toUpperCase()}'),
                  subtitle: Text(
                    slide.data.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _keys.remove(index);
                      notifier.removeSlide(index);
                    },
                  ),
                );
              },
            ),
    );
  }

  CardTemplate _templateFor(CarouselSlideType type) => switch (type) {
    CarouselSlideType.cover => CardTemplate.socialPost,
    CarouselSlideType.stat => CardTemplate.topStats,
    CarouselSlideType.quote => CardTemplate.headlineQuote,
    CarouselSlideType.cta => CardTemplate.socialPost,
  };

  void _showAddSheet(BuildContext context, CarouselComposer notifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            for (final type in CarouselSlideType.values)
              ListTile(
                title: Text(type.name.toUpperCase()),
                onTap: () {
                  notifier.addSlide(
                    CarouselSlide(
                      type: type,
                      data: CardData.sparse(
                        headline: type == CarouselSlideType.quote
                            ? 'Add a short quote'
                            : 'Slide ${ref.read(carouselComposerProvider).slides.length + 1}',
                        subtext: '',
                      ),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    final service = getIt<ExportService>();
    final bytes = <List<int>>[];
    for (final entry in _keys.entries) {
      final key = entry.value;
      try {
        bytes.add(
          await service.capturePng(
            key,
            pixelRatio: ExportService.pixelRatio(
              ref.read(carouselComposerProvider).masterSize,
            ),
          ),
        );
      } catch (_) {}
    }
    if (bytes.isEmpty || !mounted) return;
    await service.sharePages(bytes);
  }
}
