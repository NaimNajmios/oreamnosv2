class HashtagGroup {
  final String id;
  final String name;
  final String hashtags;
  final bool isDefault;

  const HashtagGroup({
    required this.id,
    required this.name,
    required this.hashtags,
    this.isDefault = false,
  });

  HashtagGroup copyWith({
    String? id,
    String? name,
    String? hashtags,
    bool? isDefault,
  }) {
    return HashtagGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      hashtags: hashtags ?? this.hashtags,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hashtags': hashtags,
        'isDefault': isDefault,
      };

  factory HashtagGroup.fromJson(Map<String, dynamic> json) {
    return HashtagGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      hashtags: json['hashtags'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

