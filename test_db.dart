void main() {
  print(getProxyUrl('https://mstdn.social/@username', 'https://rsshub.app'));
  print(getProxyUrl('https://mastodon.social/@Gargron', 'https://rsshub.app'));
  print(getProxyUrl('https://pawoo.net/@test', 'https://rsshub.app'));
}

String getProxyUrl(String originalUrl, String rssHubUrl) {
  try {
      final uri = Uri.parse(originalUrl);
      var domain = uri.host.toLowerCase();
      if (domain.isEmpty) return originalUrl;

      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }

      final path = uri.path;
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      
      final proxyBaseUrl = rssHubUrl.endsWith('/')
            ? rssHubUrl.substring(0, rssHubUrl.length - 1)
            : rssHubUrl;

        // Mastodon Route
        if (domain.contains('mastodon.') ||
            domain == 'mastodon.social' ||
            domain == 'mstdn.social' || 
            domain == 'pawoo.net') {
          if (pathSegments.length == 1 && pathSegments[0].startsWith('@')) {
            final username = pathSegments[0].substring(1); // Remove the @
            return '$proxyBaseUrl/mastodon/acct/$username@$domain/statuses';
          }
        }
      
    } catch (_) {
      // If parsing fails, just return original
    }
    return originalUrl;
}
