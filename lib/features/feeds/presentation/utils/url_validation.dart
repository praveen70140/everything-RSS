class UrlValidationResult {
  final bool isValid;
  final String? normalizedUrl;
  final String? message;

  UrlValidationResult({required this.isValid, this.normalizedUrl, this.message});
}

String normalizeHttpUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;

  String url = trimmed;
  // If it doesn't contain a scheme (colon followed by //), prepend https://
  if (!url.contains('://')) {
    url = 'https://$url';
  }
  return url;
}

UrlValidationResult validateHttpUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return UrlValidationResult(isValid: false, message: 'URL cannot be empty');
  }

  String url = normalizeHttpUrl(trimmed);

  try {
    final uri = Uri.parse(url);
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return UrlValidationResult(
          isValid: false,
          message: 'Scheme ${uri.scheme} is not supported. Use http or https.');
    }
    if (!uri.hasAuthority || uri.host.isEmpty) {
      return UrlValidationResult(isValid: false, message: 'Invalid host');
    }
    return UrlValidationResult(isValid: true, normalizedUrl: url);
  } catch (e) {
    return UrlValidationResult(isValid: false, message: 'Malformed URL: $e');
  }
}

bool isLikelyFeedUrl(String url) {
  final lowUrl = url.toLowerCase();
  return lowUrl.contains('rss') ||
      lowUrl.contains('xml') ||
      lowUrl.contains('atom') ||
      lowUrl.contains('feed') ||
      lowUrl.contains('.json') ||
      // Many sites just use the root URL
      !lowUrl.contains('.');
}
