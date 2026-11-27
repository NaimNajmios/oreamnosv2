import 'package:flutter/material.dart' hide CardTheme;

import '../../../config/theme/card_theme.dart';

/// One player in the club roster. Photos and cutouts are user-supplied files.
class RosterPlayer {
  const RosterPlayer({
    required this.name,
    this.photoPath,
    this.cutoutPath,
    this.position,
    this.number,
  });

  final String name;
  final String? photoPath;
  final String? cutoutPath;
  final String? position;
  final String? number;

  Map<String, dynamic> toJson() => {
    'name': name,
    'photoPath': photoPath,
    'cutoutPath': cutoutPath,
    'position': position,
    'number': number,
  };

  factory RosterPlayer.fromJson(Map<String, dynamic> json) => RosterPlayer(
    name: json['name'] as String? ?? 'Unknown',
    photoPath: json['photoPath'] as String?,
    cutoutPath: json['cutoutPath'] as String?,
    position: json['position'] as String?,
    number: json['number'] as String?,
  );
}

/// Set-up once per club: identity, kit colours, crest and roster.
class ClubProfile {
  const ClubProfile({
    required this.name,
    this.handle,
    this.homeColors = const [Color(0xFF1A237E), Color(0xFF0D47A1)],
    this.awayColors = const [Color(0xFFFFFFFF), Color(0xFFB0BEC5)],
    this.thirdColors = const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    this.crestPath,
    this.fontFamily,
    this.lockupPosition = 'bottomLeft',
    this.roster = const [],
  });

  final String name;
  final String? handle;
  final List<Color> homeColors;
  final List<Color> awayColors;
  final List<Color> thirdColors;
  final String? crestPath;
  final String? fontFamily;
  final String lockupPosition;
  final List<RosterPlayer> roster;

  List<Color> colorsFor(KitMode kit) => switch (kit) {
    KitMode.home => homeColors,
    KitMode.away => awayColors,
    KitMode.third => thirdColors,
  };

  Map<String, dynamic> toJson() => {
    'name': name,
    'handle': handle,
    'homeColors': homeColors.map((c) => c.toARGB32()).toList(),
    'awayColors': awayColors.map((c) => c.toARGB32()).toList(),
    'thirdColors': thirdColors.map((c) => c.toARGB32()).toList(),
    'crestPath': crestPath,
    'fontFamily': fontFamily,
    'lockupPosition': lockupPosition,
    'roster': roster.map((p) => p.toJson()).toList(),
  };

  factory ClubProfile.fromJson(Map<String, dynamic> json) => ClubProfile(
    name: json['name'] as String? ?? 'Club',
    handle: json['handle'] as String?,
    homeColors: _colors(json['homeColors'], const [
      Color(0xFF1A237E),
      Color(0xFF0D47A1),
    ]),
    awayColors: _colors(json['awayColors'], const [
      Color(0xFFFFFFFF),
      Color(0xFFB0BEC5),
    ]),
    thirdColors: _colors(json['thirdColors'], const [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
    ]),
    crestPath: json['crestPath'] as String?,
    fontFamily: json['fontFamily'] as String?,
    lockupPosition: json['lockupPosition'] as String? ?? 'bottomLeft',
    roster: (json['roster'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RosterPlayer.fromJson)
        .toList(),
  );

  static List<Color> _colors(dynamic raw, List<Color> fallback) {
    if (raw is! List) return fallback;
    final colors = raw.whereType<int>().map((v) => Color(v)).toList();
    return colors.length >= 2 ? colors : fallback;
  }
}
