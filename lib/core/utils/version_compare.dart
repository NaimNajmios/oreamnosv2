/// Version helpers for the in-app update check.
///
/// Deliberately dependency-free and pure so the rules can be unit-tested
/// exhaustively. Supports `MAJOR.MINOR.PATCH` with an optional `-prerelease`
/// suffix and ignores build metadata (`+5`).
library;

/// Strips a leading `v`/`V` and any `+build` metadata.
String stripVersionPrefix(String version) {
  final trimmed = version.trim();
  return trimmed.replaceFirst(RegExp(r'^[vV]'), '').split('+').first.trim();
}

/// The numeric `MAJOR.MINOR.PATCH` parts, with unparseable parts treated as 0.
List<int> _coreParts(String version) {
  final core = stripVersionPrefix(version).split('-').first;
  return core
      .split('.')
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList(growable: false);
}

/// The identifier list after the first `-`, or `null` when the version is a
/// final release.
List<String>? _prereleaseParts(String version) {
  final normalized = stripVersionPrefix(version);
  final index = normalized.indexOf('-');
  if (index < 0) return null;
  final suffix = normalized.substring(index + 1);
  if (suffix.isEmpty) return null;
  return suffix.split('.');
}

int? _asInt(String value) {
  if (value.isEmpty) return null;
  for (final unit in value.codeUnits) {
    if (unit < 0x30 || unit > 0x39) return null;
  }
  return int.tryParse(value);
}

/// Compares two prerelease identifier lists using semver precedence:
/// numeric identifiers compare numerically and rank below alphanumeric ones,
/// and a longer list wins when every shared identifier is equal.
int _comparePrerelease(List<String> a, List<String> b) {
  final shared = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < shared; i++) {
    final left = a[i];
    final right = b[i];
    final leftNumber = _asInt(left);
    final rightNumber = _asInt(right);
    if (leftNumber != null && rightNumber != null) {
      final compared = leftNumber.compareTo(rightNumber);
      if (compared != 0) return compared;
      continue;
    }
    if (leftNumber != null) return -1;
    if (rightNumber != null) return 1;
    final compared = left.compareTo(right);
    if (compared != 0) return compared;
  }
  return a.length.compareTo(b.length);
}

/// Returns a negative number when [a] is older than [b], zero when they are
/// equivalent, and a positive number when [a] is newer.
///
/// A pre-release sorts before the same core version (`1.2.0-beta.1` < `1.2.0`),
/// and prerelease identifiers are ordered (`beta.1` < `beta.2` < `beta.10`).
/// Unparseable input never throws; missing numeric parts count as 0.
int compareVersions(String a, String b) {
  final left = _coreParts(a);
  final right = _coreParts(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    if (x != y) return x.compareTo(y);
  }

  final leftPre = _prereleaseParts(a);
  final rightPre = _prereleaseParts(b);
  if (leftPre == null && rightPre == null) return 0;
  if (leftPre == null) return 1;
  if (rightPre == null) return -1;
  return _comparePrerelease(leftPre, rightPre);
}

/// True when [candidate] is strictly newer than [current].
bool isNewerVersion(String candidate, String current) =>
    compareVersions(candidate, current) > 0;
