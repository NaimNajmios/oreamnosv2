class UsageLog {
  final String id;
  final DateTime timestamp;
  final String providerId;
  final String? modelName;
  final int latencyMs;
  final int estimatedTokens;
  final bool isSuccess;

  const UsageLog({
    required this.id,
    required this.timestamp,
    required this.providerId,
    this.modelName,
    required this.latencyMs,
    required this.estimatedTokens,
    required this.isSuccess,
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
    );
  }
}
