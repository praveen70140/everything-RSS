import 'package:xml/xml.dart';
import '../../../../core/database/local_db.dart';
import '../models/local_feed_folder.dart';
import '../models/local_feed_item.dart';

class OpmlService {
  static Future<void> importOpml(String xmlString) async {
    try {
      final document = XmlDocument.parse(xmlString);
      final body = document.findAllElements('body').first;
      final outlines = body.findElements('outline');

      for (var outline in outlines) {
        final title = outline.getAttribute('title') ?? outline.getAttribute('text') ?? 'Unknown Folder';
        final type = outline.getAttribute('type');

        if (type == null || type != 'rss') {
          // It's a folder
          final children = outline.findElements('outline');
          if (children.isNotEmpty) {
            final folder = LocalFeedFolder()
              ..name = title
              ..isExpanded = true
              ..sortOrder = (await localDb.getFolders()).length;
            await localDb.saveFolder(folder);

            for (var child in children) {
              await _saveFeedNode(child, folderId: folder.id);
            }
          }
        } else {
          // It's a top-level feed
          await _saveFeedNode(outline);
        }
      }
    } catch (e) {
      print('OPML Import Error: $e');
      rethrow;
    }
  }

  static Future<void> _saveFeedNode(XmlElement outline, {int? folderId}) async {
    final title = outline.getAttribute('title') ?? outline.getAttribute('text') ?? 'Unknown Feed';
    final xmlUrl = outline.getAttribute('xmlUrl');
    
    if (xmlUrl != null && xmlUrl.isNotEmpty) {
      final feed = LocalFeedItem()
        ..name = title
        ..url = xmlUrl
        ..folderId = folderId
        ..sortOrder = (await localDb.getFeeds()).where((f) => f.folderId == folderId).length;
      await localDb.saveFeed(feed);
    }
  }

  static Future<String> exportOpml() async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('opml', attributes: {'version': '2.0'}, nest: () {
      builder.element('head', nest: () {
        builder.element('title', nest: 'Evreything RSS Export');
      });
      builder.element('body', nest: () async {
        final folders = await localDb.getFolders();
        final feeds = await localDb.getFeeds();

        // Add feeds without a folder
        final rootFeeds = feeds.where((f) => f.folderId == null);
        for (var feed in rootFeeds) {
          builder.element('outline', attributes: {
            'text': feed.name,
            'title': feed.name,
            'type': 'rss',
            'xmlUrl': feed.url,
          });
        }

        // Add folders and their feeds
        for (var folder in folders) {
          builder.element('outline', attributes: {
            'text': folder.name,
            'title': folder.name,
          }, nest: () {
            final folderFeeds = feeds.where((f) => f.folderId == folder.id);
            for (var feed in folderFeeds) {
              builder.element('outline', attributes: {
                'text': feed.name,
                'title': feed.name,
                'type': 'rss',
                'xmlUrl': feed.url,
              });
            }
          });
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true);
  }
}
