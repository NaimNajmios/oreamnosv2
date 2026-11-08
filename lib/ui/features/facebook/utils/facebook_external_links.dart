import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oreamnos/domain/models/facebook_post_record.dart';

/// Resolves a Facebook feed-post URI, accepting only http(s) links.
///
/// Returns `null` for Story-only records (empty permalink), scheduled posts
/// without a live permalink, and malformed or non-web values.
Uri? facebookPostUri(String permalink) {
  final raw = permalink.trim();
  if (raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri;
}

/// The external feed-post URI for [record], or `null` when it has none.
Uri? feedPostUri(FacebookPostRecord record) =>
    facebookPostUri(record.permalink);

/// Opens the record's Facebook feed post in the external browser/app.
///
/// Never logs the URL. When [missingMessage] is provided and the record has no
/// usable permalink, it is shown instead of opening an empty URI.
Future<void> openFacebookPost(
  BuildContext context,
  FacebookPostRecord record, {
  String? missingMessage,
}) {
  return openFacebookPermalink(
    context,
    record.permalink,
    missingMessage: missingMessage,
  );
}

/// Opens a raw permalink in the external browser/app.
///
/// Never logs the URL. When [missingMessage] is provided and the permalink is
/// not a usable web link, it is shown instead of opening an empty URI.
Future<void> openFacebookPermalink(
  BuildContext context,
  String permalink, {
  String? missingMessage,
}) async {
  final uri = facebookPostUri(permalink);
  if (uri == null) {
    if (missingMessage != null && context.mounted) {
      _showSnack(context, missingMessage);
    }
    return;
  }
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showSnack(context, 'Could not open the link');
    }
  } catch (_) {
    if (context.mounted) {
      _showSnack(context, 'Could not open the link');
    }
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
