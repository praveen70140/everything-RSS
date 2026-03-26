import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/feed_entry.dart';

class RssService {
  Future<List<FeedEntry>> fetchFeed(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        },
      );
      
      if (response.statusCode == 200) {
        // Decode body handling potential encoding issues and File/Byte streams
        String xmlString;
        try {
          xmlString = utf8.decode(response.bodyBytes, allowMalformed: true);
        } catch (_) {
          // Fallback if utf8 fails completely
          xmlString = String.fromCharCodes(response.bodyBytes);
        }

        // Clean up BOM (Byte Order Mark) if present (common in file-served XML)
        if (xmlString.startsWith('\ufeff')) {
          xmlString = xmlString.substring(1);
        }
        
        final document = XmlDocument.parse(xmlString);
        
        final items = document.findAllElements('item');
        List<FeedEntry> entries = [];
        
        for (var item in items) {
          final title = _getElementText(item, 'title') ?? 'No Title';
          final link = _getElementText(item, 'link') ?? '';
          String description = _getElementText(item, 'description') ?? '';
          
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
              
              if (type.startsWith('video') || (mediaContent.getAttribute('medium') == 'video')) {
                mediaType = MediaType.video;
              } else if (type.startsWith('audio') || (mediaContent.getAttribute('medium') == 'audio')) {
                mediaType = MediaType.audio;
              } else if (type.startsWith('image') || (mediaContent.getAttribute('medium') == 'image')) {
                mediaType = MediaType.image;
              } else if (mediaUrl != null && (mediaUrl.endsWith('.jpg') || mediaUrl.endsWith('.png'))) {
                mediaType = MediaType.image;
              }
            }
          }

          // Fallback check for images hidden in description HTML before we stripped it
          if (mediaType == MediaType.text) {
             final rawDesc = _getElementText(item, 'description') ?? '';
             final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(rawDesc);
             if (imgMatch != null) {
               mediaUrl = imgMatch.group(1);
               mediaType = MediaType.image;
             }
          }

          entries.add(FeedEntry(
            id: link.isNotEmpty ? link : DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            subtitle: description,
            link: link,
            mediaType: mediaType,
            mediaUrl: mediaUrl,
          ));
        }
        
        return entries;
      } else {
        throw Exception('Failed to load RSS feed (Status: ${response.statusCode})');
      }
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
