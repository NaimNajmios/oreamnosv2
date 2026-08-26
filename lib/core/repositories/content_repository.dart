import '../../data/models/ai_provider.dart';
import '../../data/services/curator_factory.dart';
import '../../domain/models/curated_post.dart';

abstract class IContentRepository {
  Future<CuratedPost> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
  });

  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  });

  Future<String> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
  });
}

class ContentRepository implements IContentRepository {
  @override
  Future<CuratedPost> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
  }) async {
    final curator = CuratorFactory.getCurator(provider);
    return curator.generateStructuredPost(
      content: content,
      modelId: modelId,
      apiKey: apiKey,
      sourceUrl: sourceUrl,
    );
  }

  @override
  Future<String> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  }) async {
    final curator = CuratorFactory.getCurator(provider);
    return curator.generatePost(
      contentOrUrl: contentOrUrl,
      modelId: modelId,
      apiKey: apiKey,
      tone: tone,
      defaultHashtags: defaultHashtags,
    );
  }

  @override
  Future<String> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
  }) async {
    final curator = CuratorFactory.getCurator(provider);
    return await curator.rewriteField(
      text: text,
      fieldName: fieldName,
      modelId: modelId,
      apiKey: apiKey,
    );
  }
}
