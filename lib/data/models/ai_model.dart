class AiModel {
  final String id;
  final bool isFree;
  final bool supportsVision;

  const AiModel({
    required this.id,
    this.isFree = false,
    this.supportsVision = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiModel &&
        other.id == id &&
        other.isFree == isFree &&
        other.supportsVision == supportsVision;
  }

  @override
  int get hashCode => id.hashCode ^ isFree.hashCode ^ supportsVision.hashCode;
}
