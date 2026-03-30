import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/feed_entry.dart';
import '../../../../core/database/local_db.dart';

class RssService {
  Future<List<FeedEntry>> fetchFeed(String url,
      {bool forceRefresh = false,
      String? feedName,
      String? originalUrl}) async {
    try {
      String xmlString = '';
      bool fromCache = false;

      // Use the original URL for caching if provided (since the proxy url might change or be irrelevant for cache keys)
      final cacheKey = originalUrl ?? url;

      if (!forceRefresh) {
        final cached = await localDb.getCachedFeedXml(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          xmlString = cached;
          fromCache = true;
        }
      }

      if (!fromCache) {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'application/rss+xml, application/xml, text/xml, */*',
          },
        );

        if (response.statusCode == 200) {
          try {
            xmlString = utf8.decode(response.bodyBytes, allowMalformed: true);
          } catch (_) {
            xmlString = String.fromCharCodes(response.bodyBytes);
          }

          if (xmlString.startsWith('\ufeff')) {
            xmlString = xmlString.substring(1);
          }

          await localDb.saveCachedFeedXml(cacheKey, xmlString);
        } else {
          throw Exception(
              'Failed to load RSS feed (Status: ${response.statusCode})');
        }
      }

      if (xmlString.isNotEmpty) {
        final document = XmlDocument.parse(xmlString);

        final items = document.findAllElements('item');
        List<FeedEntry> entries = [];

        for (var item in items) {
          final title = _getElementText(item, 'title') ?? 'No Title';
          final link = _getElementText(item, 'link') ?? '';
          String description = _getElementText(item, 'description') ?? '';

          String? author = _getElementText(item, 'dc:creator') ??
              _getElementText(item, 'author');

          DateTime? pubDate;
          final pubDateStr = _getElementText(item, 'pubDate');
          if (pubDateStr != null && pubDateStr.isNotEmpty) {
            try {
              pubDate = HttpDate.parse(pubDateStr);
            } catch (_) {
              try {
                // Fallback for atom format or other formats
                pubDate = DateTime.parse(pubDateStr);
              } catch (_) {}
            }
          }

          // Clean up HTML tags from description for a clean subtitle
          description = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (description.length > 150) {
            description = '${description.substring(0, 150)}...';
          }

          String? mediaUrl;
          MediaType mediaType = MediaType.text;

          // Check standard enclosures
          final enclosures = item.findElements('enclosure');
          if (enclosures.isNotEmpty) {
            final enclosure = enclosures.first;
            final type = enclosure.getAttribute('type') ?? '';
            mediaUrl = enclosure.getAttribute('url');

            if (type.startsWith('video')) {
              mediaType = MediaType.video;
            } else if (type.startsWith('audio')) {
              mediaType = MediaType.audio;
            } else if (type.startsWith('image')) {
              mediaType = MediaType.image;
            }
          }

          // Check media:content (common in news feeds)
          if (mediaType == MediaType.text) {
            final mediaContents = item.findAllElements('media:content');
            if (mediaContents.isNotEmpty) {
              final mediaContent = mediaContents.first;
              final type = mediaContent.getAttribute('type') ?? '';
              mediaUrl = mediaContent.getAttribute('url');

              if (type.startsWith('video') ||
                  (mediaContent.getAttribute('medium') == 'video')) {
                mediaType = MediaType.video;
              } else if (type.startsWith('audio') ||
                  (mediaContent.getAttribute('medium') == 'audio')) {
                mediaType = MediaType.audio;
              } else if (type.startsWith('image') ||
                  (mediaContent.getAttribute('medium') == 'image')) {
                mediaType = MediaType.image;
              } else if (mediaUrl != null &&
                  (mediaUrl.endsWith('.jpg') || mediaUrl.endsWith('.png'))) {
                mediaType = MediaType.image;
              }
            }
          }

          // Fallback check for images hidden in description HTML before we stripped it
          if (mediaType == MediaType.text) {
            final rawDesc = _getElementText(item, 'description') ?? '';
            final imgMatch =
                RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(rawDesc);
            if (imgMatch != null) {
              mediaUrl = imgMatch.group(1);
              mediaType = MediaType.image;
            }
          }

          entries.add(FeedEntry(
            id: link.isNotEmpty
                ? link
                : DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            subtitle: description,
            link: link,
            mediaType: mediaType,
            mediaUrl: mediaUrl,
            author: author,
            pubDate: pubDate,
            feedName: feedName,
            feedUrl: originalUrl ?? url,
          ));
        }

        return entries;
      }

      return [];
    } catch (e) {
      print('Error fetching RSS: $e');
      return [];
    }
  }

  String? _getElementText(XmlElement element, String name) {
    final elements = element.findElements(name);
    if (elements.isNotEmpty) {
      return elements.first.innerText;
    }
    return null;
  }
}
