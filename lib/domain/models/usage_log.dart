class UsageLog {
  final String id;
  final DateTime timestamp;
  final String providerId;
  final int latencyMs;
  final int estimatedTokens;
  final bool isSuccess;

  const UsageLog({
    required this.id,
    required this.timestamp,
    required this.providerId,
    required this.latencyMs,
    required this.estimatedTokens,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'providerId': providerId,
        'latencyMs': latencyMs,
        'estimatedTokens': estimatedTokens,
        'isSuccess': isSuccess,
      };

  factory UsageLog.fromJson(Map<String, dynamic> json) {
    return UsageLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      providerId: json['providerId'] as String,
      latencyMs: json['latencyMs'] as int,
      estimatedTokens: json['estimatedTokens'] as int,
      isSuccess: json['isSuccess'] as bool,
    );
  }
}

