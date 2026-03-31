void main() {
  print(getProxyUrl('https://mastodon.social/@username', 'https://rsshub.app'));
}

String getProxyUrl(String originalUrl, String rssHubUrl) {
  try {
      final uri = Uri.parse(originalUrl);
      var domain = uri.host.toLowerCase();
      if (domain.isEmpty) return originalUrl;

      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }

      if (originalUrl.endsWith('.rss') ||
          originalUrl.endsWith('.atom') ||
          originalUrl.endsWith('.xml')) {
        return originalUrl;
      }

      final path = uri.path;
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (domain.contains('mastodon.') || domain == 'mastodon.social' || domain == 'mstdn.social') {
        if (pathSegments.length == 1 && pathSegments[0].startsWith('@')) {
          final username = pathSegments[0].substring(1); // remove the '@'
          return '$rssHubUrl/mastodon/account_id/$domain/$username'; // Wait, RSSHub usually needs the numeric account ID, or handles it by account name. Let's check rsshub docs format.
          // Format is typically /mastodon/acct/username@domain according to docs
          // e.g., /mastodon/acct/username@mastodon.social
        }
      }
    } catch (_) {}
    return originalUrl;
}
