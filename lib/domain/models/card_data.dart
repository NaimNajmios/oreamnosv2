import 'package:equatable/equatable.dart';

class CardData extends Equatable {
  final Map<String, dynamic> data;

  const CardData({
    required this.data,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(data: Map<String, dynamic>.from(json));
  }

  /// Lightweight companion factory — headline + subtext + optional microStat.
  factory CardData.fromBrief({
    required String headline,
    required String subtext,
    String? microStat,
  }) {
    return CardData(data: {
      'headline': headline,
      'subtext': subtext,
      if (microStat != null && microStat.trim().isNotEmpty) 'microStat': microStat.trim(),
    });
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  @override
  List<Object?> get props => [data];

  // --- Sparse canonical fields ---
  String get headline =>
      (data['headline'] as String?)?.trim().isNotEmpty == true
          ? (data['headline'] as String).trim()
          : (data['title'] as String?)?.trim().isNotEmpty == true
              ? (data['title'] as String).trim()
              : (data['playerName'] as String?)?.trim().isNotEmpty == true
                  ? (data['playerName'] as String).trim()
                  : 'Generated Card';

  String get subtext =>
      (data['subtext'] as String?)?.trim() ??
      (data['subtitle'] as String?)?.trim() ??
      (data['quote'] as String?)?.trim() ??
      (data['keyQuote'] as String?)?.trim() ??
      '';

  String? get microStat {
    final v = data['microStat'] ?? data['keyAction'] ?? data['statBadge'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  // Legacy compat — canvas & export still use title/subtitle
  String get title => headline;
  String get subtitle => subtext;

  bool get hasMicroStat => microStat != null && microStat!.isNotEmpty;
  bool get isEmpty => headline == 'Generated Card' && subtext.isEmpty && !hasMicroStat;

  CardData copyWith({
    String? headline,
    String? subtext,
    String? microStat,
    bool clearMicroStat = false,
  }) {
    final next = Map<String, dynamic>.from(data);
    if (headline != null) next['headline'] = headline;
    if (subtext != null) next['subtext'] = subtext;
    if (clearMicroStat) {
      next.remove('microStat');
    } else if (microStat != null) {
      next['microStat'] = microStat;
    }
    return CardData(data: next);
  }
}

