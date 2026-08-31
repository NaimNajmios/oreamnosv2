import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../../core/di/injection.dart';

import 'package:dio/dio.dart';

import '../../core/error/failures.dart';
import '../../data/models/ai_provider.dart';
import '../../data/services/curator_factory.dart';
import '../../domain/models/curated_post.dart';

abstract class IContentRepository {
  Future<Result<CuratedPost>> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
    List<String> searchSources = const [],
    bool keepStructure = false,
    bool isFanModeEnabled = false,
    String fanClubName = '',
  });

  Future<Result<String>> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  });

  Future<Result<String>> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
  });
}

@LazySingleton(as: IContentRepository)
class ContentRepository implements IContentRepository {
  Failure _mapError(Object e, StackTrace? st) {
    if (e is DioException) {
      final extra = e.requestOptions.extra['failure'];
      if (extra is Failure) return extra;
    }
    if (e is Failure) return e;
    final msg = e.toString().toLowerCase();
    if (msg.contains('429') ||
        msg.contains('rate limit') ||
        msg.contains('quota') ||
        msg.contains('resource_exhausted')) {
      return RateLimitFailure(e.toString());
    }
    if (msg.contains('401') ||
        msg.contains('403') ||
        msg.contains('unauthorized') ||
        msg.contains('invalid api key') ||
        msg.contains('permission')) {
      return AuthFailure(e.toString());
    }
    if (msg.contains('timeout') ||
        msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection')) {
      return NetworkFailure(e.toString());
    }
    if (msg.contains('parse') || msg.contains('json')) {
      return ParseFailure(e.toString());
    }
    return UnknownFailure(e.toString());
  }

  @override
  Future<Result<CuratedPost>> generateStructuredPost({
    required dynamic content,
    required String modelId,
    required String apiKey,
    String? sourceUrl,
    required AiProvider provider,
    List<String> searchSources = const [],
    bool keepStructure = false,
    bool isFanModeEnabled = false,
    String fanClubName = '',
  }) async {
    try {
      final curator = CuratorFactory.getCurator(provider);
      final res = await curator.generateStructuredPost(
        content: content,
        modelId: modelId,
        apiKey: apiKey,
        sourceUrl: sourceUrl,
        searchSources: searchSources,
        keepStructure: keepStructure,
        isFanModeEnabled: isFanModeEnabled,
        fanClubName: fanClubName,
      );
      return ResultSuccess(res);
    } catch (e, st) {
      return ResultError(_mapError(e, st));
    }
  }

  @override
  Future<Result<String>> generatePost({
    required String contentOrUrl,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
    required String tone,
    required String defaultHashtags,
  }) async {
    try {
      final curator = CuratorFactory.getCurator(provider);
      final res = await curator.generatePost(
        contentOrUrl: contentOrUrl,
        modelId: modelId,
        apiKey: apiKey,
        tone: tone,
        defaultHashtags: defaultHashtags,
      );
      return ResultSuccess(res);
    } catch (e, st) {
      return ResultError(_mapError(e, st));
    }
  }

  @override
  Future<Result<String>> rewriteField({
    required String text,
    required String fieldName,
    required String modelId,
    required String apiKey,
    required AiProvider provider,
  }) async {
    try {
      final curator = CuratorFactory.getCurator(provider);
      final res = await curator.rewriteField(
        text: text,
        fieldName: fieldName,
        modelId: modelId,
        apiKey: apiKey,
      );
      return ResultSuccess(res);
    } catch (e, st) {
      return ResultError(_mapError(e, st));
    }
  }
}

final contentRepositoryProvider = Provider<IContentRepository>(
  (ref) => getIt<IContentRepository>(),
);
