import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oreamnos/domain/models/curated_post.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_state.dart';
import 'package:oreamnos/ui/features/generate/view_models/generate_view_model.dart';
import 'package:oreamnos/ui/features/publish/view_models/publish_handoff_view_model.dart';

class _FakeGenerateViewModel extends GenerateViewModel {
  _FakeGenerateViewModel(this.initial);

  final GenerateUiState initial;

  @override
  GenerateUiState build() => initial;
}

const _post = CuratedPost(
  title: 'A headline',
  bodyMarkdown: 'Body copy that will be published.',
  hashtags: ['flutter', 'dart'],
  source: SourceAttribution(label: 'Example', url: 'https://example.com/story'),
  rawMarkdown: 'A headline\n\nBody copy that will be published.',
);

ProviderContainer _container(GenerateUiState state) {
  final container = ProviderContainer(
    overrides: [
      generateViewModelProvider.overrideWith(
        () => _FakeGenerateViewModel(state),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('publishHandoffProvider', () {
    test('derives a ready handoff from the generated post', () {
      final container = _container(
        const GenerateUiState(curatedPost: _post, uppercaseTitle: true),
      );

      final handoff = container.read(publishHandoffProvider);

      expect(handoff, isNotNull);
      expect(handoff!.title, 'A headline');
      expect(handoff.text, contains('Body copy that will be published.'));
      expect(handoff.text, contains('#flutter'));
      expect(handoff.uppercaseTitle, isTrue);
      expect(handoff.hashtagCount, 2);
      expect(handoff.sourceUrl, 'https://example.com/story');
      expect(handoff.sourceLabel, 'Example');
      expect(handoff.sourceDomain, 'example.com');
      expect(handoff.sourceDisplay, 'Example');
      expect(handoff.snippet, isNotEmpty);
    });

    test('returns null when there is no generated post', () {
      final container = _container(const GenerateUiState());

      expect(container.read(publishHandoffProvider), isNull);
    });

    test('returns null when the visible text is empty', () {
      final container = _container(
        const GenerateUiState(
          curatedPost: CuratedPost(
            title: '',
            bodyMarkdown: '',
            hashtags: [],
            source: SourceAttribution(label: ''),
            rawMarkdown: '',
          ),
        ),
      );

      expect(container.read(publishHandoffProvider), isNull);
    });

    test('consume clears the handoff but keeps the generated post', () {
      final container = _container(const GenerateUiState(curatedPost: _post));
      final notifier = container.read(publishHandoffProvider.notifier);
      expect(container.read(publishHandoffProvider), isNotNull);

      notifier.consume();

      expect(container.read(publishHandoffProvider), isNull);
      expect(container.read(generateViewModelProvider).curatedPost, isNotNull);
    });

    test('markFresh surfaces an already-consumed post again', () {
      final container = _container(const GenerateUiState(curatedPost: _post));
      final notifier = container.read(publishHandoffProvider.notifier);
      notifier.consume();
      expect(container.read(publishHandoffProvider), isNull);

      notifier.markFresh();

      expect(container.read(publishHandoffProvider), isNotNull);
    });

    test('falls back to the domain when the source label is empty', () {
      const post = CuratedPost(
        title: 'A headline',
        bodyMarkdown: 'Body copy.',
        hashtags: [],
        source: SourceAttribution(
          label: '',
          url: 'https://example.com/story',
          domain: 'example.com',
        ),
        rawMarkdown: 'A headline\n\nBody copy.',
      );
      final handoff = _container(const GenerateUiState(curatedPost: post))
          .read(publishHandoffProvider);

      expect(handoff!.sourceDisplay, 'example.com');
    });

    test('source changes produce a new fingerprint', () {
      const first = CuratedPost(
        title: 'A headline',
        bodyMarkdown: 'Body copy.',
        hashtags: [],
        source: SourceAttribution(
          label: 'Example',
          url: 'https://example.com/a',
          domain: 'example.com',
        ),
        rawMarkdown: 'A headline\n\nBody copy.',
      );
      const second = CuratedPost(
        title: 'A headline',
        bodyMarkdown: 'Body copy.',
        hashtags: [],
        source: SourceAttribution(
          label: 'Example',
          url: 'https://example.com/b',
          domain: 'other.example.com',
        ),
        rawMarkdown: 'A headline\n\nBody copy.',
      );

      final a = _container(const GenerateUiState(curatedPost: first))
          .read(publishHandoffProvider)!;
      final b = _container(const GenerateUiState(curatedPost: second))
          .read(publishHandoffProvider)!;

      expect(a.fingerprint, isNot(b.fingerprint));
    });

    test('snippet trims to the first non-empty line', () {
      final handoff = PublishHandoff(
        fingerprint: 'f',
        text: '\n\nFirst line\nSecond line',
        title: 'T',
        uppercaseTitle: false,
        hashtagCount: 0,
        sourceUrl: '',
        createdAt: DateTime(2026, 11, 8),
      );

      expect(handoff.snippet, 'First line');
    });
  });
}
