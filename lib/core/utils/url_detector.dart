class UrlDetector {
  static const twitterHosts = {
    'x.com',
    'www.x.com',
    'twitter.com',
    'www.twitter.com',
    'mobile.twitter.com',
    'm.twitter.com',
    'vxtwitter.com',
    'fxtwitter.com',
    'fixupx.com',
    'nitter.net',
    'nitter.privacydev.net',
  };

  static UrlType classifyUrl(String url) {
    var raw = url.trim();
    if (raw.isEmpty) return UrlType.notUrl;

    if (!raw.toLowerCase().startsWith('http://') &&
        !raw.toLowerCase().startsWith('https://')) {
      raw = 'https://$raw';
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return UrlType.notUrl;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (twitterHosts.contains(host) &&
        (path.contains('/status/') ||
            path.contains('/i/web/status/') ||
            path.contains('/i/status/'))) {
      return UrlType.twitterStatus;
    }
    if (twitterHosts.contains(host)) {
      return UrlType.twitterProfile;
    }

    if (uri.isScheme('http') || uri.isScheme('https')) {
      return UrlType.article;
    }
    return UrlType.notUrl;
  }
}

enum UrlType { notUrl, twitterStatus, twitterProfile, article }
