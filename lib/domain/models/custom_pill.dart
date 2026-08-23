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

  factory CustomPill.fromJson(Map<String, dynamic> json) {
    return CustomPill(
      label: json['label'] as String,
      instruction: json['instruction'] as String,
    );
  }
}

