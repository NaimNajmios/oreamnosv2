class UrlDetector {
  static const twitterHosts = {
    'x.com',
    'www.x.com',
    'twitter.com',
    'www.twitter.com',
    'mobile.twitter.com',
    'nitter.net',
    'nitter.privacydev.net',
  };

  static UrlType classifyUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return UrlType.notUrl;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (twitterHosts.contains(host) && path.contains('/status/')) {
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
