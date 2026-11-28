import 'package:dio/dio.dart';

import '../models/query_plan_suggestion.dart';

/// Optional AI-assisted query planning.
///
/// Implementations must fail soft: no key, quota exhaustion, 429, timeout,
/// model-not-found or malformed JSON all return `null` so the caller falls
/// back to the deterministic heuristic planner. This call is pinned to Groq
/// and never hops to another provider.
abstract class QueryPlannerAi {
  const QueryPlannerAi();

  Future<QueryPlanSuggestion?> plan({
    required String text,
    String? pageTitle,
    CancelToken? cancelToken,
  });
}

class NoopQueryPlannerAi extends QueryPlannerAi {
  const NoopQueryPlannerAi();

  @override
  Future<QueryPlanSuggestion?> plan({
    required String text,
    String? pageTitle,
    CancelToken? cancelToken,
  }) async => null;
}
