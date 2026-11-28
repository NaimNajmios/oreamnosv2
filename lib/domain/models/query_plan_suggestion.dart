/// Output of the optional Groq query-planning call.
///
/// The AI step only proposes names and 1–2 English queries. Every value is
/// validated in Dart before it reaches Tavily; nothing from this object is
/// trusted as a fact or used as a source label.
class QueryPlanSuggestion {
  const QueryPlanSuggestion({required this.entities, required this.queries});

  final List<String> entities;
  final List<String> queries;

  bool get isUsable => queries.isNotEmpty;
}
