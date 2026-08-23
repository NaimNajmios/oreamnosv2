class CustomPill {
  final String label;
  final String instruction;

  const CustomPill({
    required this.label,
    required this.instruction,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'instruction': instruction,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPill &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          instruction == other.instruction;

  @override
  int get hashCode => label.hashCode ^ instruction.hashCode;

  factory CustomPill.fromJson(Map<String, dynamic> json) {
    return CustomPill(
      label: json['label'] as String,
      instruction: json['instruction'] as String,
    );
  }
}

