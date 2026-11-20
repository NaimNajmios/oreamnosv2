import '../../core/utils/version_compare.dart';

/// A GitHub release, reduced to the fields the app actually shows.
///
/// Parsing is intentionally tolerant: the API is third-party input and a
/// malformed asset list must not crash the update check.
class AppRelease {
  const AppRelease({
    required this.tag,
    required this.version,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.publishedAt,
    required this.isPrerelease,
    this.apkUrl,
    this.apkSizeBytes,
  });

  /// Raw tag as published, e.g. `v1.2.0`.
  final String tag;

  /// Normalized version without the `v` prefix, e.g. `1.2.0`.
  final String version;

  final String name;

  /// Release notes in markdown, empty when the release has none.
  final String body;

  /// Human-facing release page.
  final String htmlUrl;

  final DateTime publishedAt;
  final bool isPrerelease;

  /// Direct download for the universal APK, when one is attached.
  final String? apkUrl;
  final int? apkSizeBytes;

  bool get hasApk => apkUrl != null && apkUrl!.isNotEmpty;

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final version = stripVersionPrefix(tag);
    final assets = json['assets'];

    String? apkUrl;
    int? apkSize;
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (!name.endsWith('.apk')) continue;
        final url = asset['browser_download_url'] as String?;
        if (url == null || url.isEmpty) continue;
        apkUrl = url;
        final size = asset['size'];
        apkSize = size is num ? size.toInt() : null;
        break;
      }
    }

    return AppRelease(
      tag: tag,
      version: version,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : (tag.isNotEmpty ? tag : version),
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      // Trust the flag, but a hyphenated tag is a pre-release by our own
      // convention even if GitHub was not told so.
      isPrerelease: json['prerelease'] == true || version.contains('-'),
      apkUrl: apkUrl,
      apkSizeBytes: apkSize,
    );
  }
}
