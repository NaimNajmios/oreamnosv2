class UsageLog {
  final String id;
  final DateTime timestamp;
  final String providerId;
  final String? modelName;
  final int latencyMs;
  final int estimatedTokens;
  final bool isSuccess;

  /// Correlates this row with request-level debug-log activity.
  final String? requestId;

  /// Short human-readable failure description for failed attempts
  /// (e.g. "Rate limited — retry in 34s"). Null on success.
  final String? error;

  /// Real prompt-token count from the API usage payload when captured.
  final int? promptTokens;

  /// Real completion-token count from the API usage payload when captured.
  final int? completionTokens;

  const UsageLog({
    required this.id,
    required this.timestamp,
    required this.providerId,
    this.modelName,
    required this.latencyMs,
    required this.estimatedTokens,
    required this.isSuccess,
    this.requestId,
    this.error,
    this.promptTokens,
    this.completionTokens,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.month}/${timestamp.day} $h:$m';
  }

  String get providerModelText {
    if (modelName != null && modelName!.isNotEmpty && modelName != 'N/A') {
      return '$providerId • $modelName';
    }
    return providerId;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'providerId': providerId,
    if (modelName != null) 'modelName': modelName,
    'latencyMs': latencyMs,
    'estimatedTokens': estimatedTokens,
    'isSuccess': isSuccess,
    if (requestId != null) 'requestId': requestId,
    if (error != null) 'error': error,
    if (promptTokens != null) 'promptTokens': promptTokens,
    if (completionTokens != null) 'completionTokens': completionTokens,
  };

  factory UsageLog.fromJson(Map<String, dynamic> json) {
    return UsageLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      providerId: json['providerId'] as String,
      modelName: json['modelName'] as String?,
      latencyMs: json['latencyMs'] as int,
      estimatedTokens: json['estimatedTokens'] as int,
      isSuccess: json['isSuccess'] as bool,
      requestId: json['requestId'] as String?,
      error: json['error'] as String?,
      promptTokens: (json['promptTokens'] as num?)?.toInt(),
      completionTokens: (json['completionTokens'] as num?)?.toInt(),
    );
  }
}
