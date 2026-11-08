/// A deterministic posting-time suggestion derived from local history.
class PostingTimeSlot {
  const PostingTimeSlot({
    required this.weekday,
    required this.hour,
    required this.score,
    required this.sampleSize,
    required this.confidence,
  });

  /// `DateTime.monday` … `DateTime.sunday`.
  final int weekday;

  /// 0–23, device-local time.
  final int hour;
  final double score;
  final int sampleSize;

  /// True when at least three published posts back this bucket.
  final bool confidence;

  static const List<String> _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get weekdayName => _weekdayNames[(weekday - 1).clamp(0, 6)];

  String get hourLabel {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final twelve = hour % 12 == 0 ? 12 : hour % 12;
    return '$twelve $suffix';
  }

  String get label => '$weekdayName · $hourLabel';

  String get detail =>
      'Based on $sampleSize ${sampleSize == 1 ? 'post' : 'posts'}';
}
