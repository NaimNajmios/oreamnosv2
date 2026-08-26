class AiModel {
  final String id;
  final bool isFree;

  const AiModel({
    required this.id,
    this.isFree = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiModel && other.id == id && other.isFree == isFree;
  }

  @override
  int get hashCode => id.hashCode ^ isFree.hashCode;
}

