import 'package:uuid/uuid.dart';

/// User-defined refinement command. Identity is the stable [id] (Android
/// `GenerationPill` parity) so edit/delete survive label changes.
class CustomPill {
  final String id;
  final String label;
  final String instruction;

  CustomPill({String? id, required this.label, required this.instruction})
    : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'instruction': instruction,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPill && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory CustomPill.fromJson(Map<String, dynamic> json) {
    return CustomPill(
      // Tolerate legacy payloads without id (pre-v4 prefs).
      id: json['id'] as String?,
      label: (json['label'] ?? json['name'] ?? '') as String,
      instruction: (json['instruction'] ?? json['command'] ?? '') as String,
    );
  }
}
