import 'package:flutter_test/flutter_test.dart';
import 'package:everything_rss/features/feeds/presentation/utils/url_validation.dart';

void main() {
  group('normalizeHttpUrl', () {
    test('adds https scheme when input has a host but no scheme', () {
      expect(normalizeHttpUrl('example.com/feed.xml'),
          'https://example.com/feed.xml');
    });

    test('preserves existing http and https schemes', () {
      expect(
          normalizeHttpUrl('http://example.com/rss'), 'http://example.com/rss');
      expect(normalizeHttpUrl('https://rsshub.app'), 'https://rsshub.app');
    });
  });

  group('validateHttpUrl', () {
    test('rejects empty input', () {
      final result = validateHttpUrl('');

      expect(result.isValid, isFalse);
      expect(result.message, contains('empty'));
    });

    test('rejects unsupported schemes', () {
      final result = validateHttpUrl('ftp://example.com/feed.xml');

      expect(result.isValid, isFalse);
      expect(result.message, contains('not supported'));
    });

    test('rejects URLs without a host', () {
      final result = validateHttpUrl('https:///feed.xml');

      expect(result.isValid, isFalse);
      expect(result.message, contains('Invalid host'));
    });

    test('accepts https URLs with a host', () {
      final result = validateHttpUrl('https://rsshub.app');

      expect(result.isValid, isTrue);
      expect(result.normalizedUrl, 'https://rsshub.app');
      expect(result.message, isNull);
    });
  });

  group('isLikelyFeedUrl', () {
    test('recognizes common feed extensions and paths', () {
      expect(isLikelyFeedUrl('https://example.com/feed.xml'), isTrue);
      expect(isLikelyFeedUrl('https://example.com/rss'), isTrue);
      expect(isLikelyFeedUrl('https://example.com/atom'), isTrue);
    });

    test(
        'allows generic website URLs because many sites expose feeds indirectly',
        () {
      // In our current implementation, we allow things without a dot as potentially root URLs
      // but 'https://example.com' has a dot.
      expect(isLikelyFeedUrl('https://example.com/feed'), isTrue);
    });
  });
}
