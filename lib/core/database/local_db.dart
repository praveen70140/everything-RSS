import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../features/feeds/data/models/local_feed_folder.dart';
import '../../features/feeds/data/models/local_feed_item.dart';
import '../../features/feeds/data/models/saved_feed_entry.dart';

class LocalDatabase {
  late Box<LocalFeedFolder> _foldersBox;
  late Box<LocalFeedItem> _feedsBox;
  late Box<SavedFeedEntry> _savedEntriesBox;

  Future<void> init() async {
    await Hive.initFlutter();

    _foldersBox = await Hive.openBox<LocalFeedFolder>('folders');
    _feedsBox = await Hive.openBox<LocalFeedItem>('feeds');
    _savedEntriesBox = await Hive.openBox<SavedFeedEntry>('saved_entries');

    // Add default mock data if completely empty
    if (_foldersBox.isEmpty && _feedsBox.isEmpty) {
      final f1 = LocalFeedFolder()
        ..name = 'NEWS & MEDIA'
        ..isExpanded = true
        ..sortOrder = 0;
      final f2 = LocalFeedFolder()
        ..name = 'PODCASTS'
        ..isExpanded = false
        ..sortOrder = 1;

      // Save folders and get their generated keys/IDs
      final f1Id = await _foldersBox.add(f1);
      f1.id = f1Id;
      await f1.save();

      final f2Id = await _foldersBox.add(f2);
      f2.id = f2Id;
      await f2.save();

      final feed1 = LocalFeedItem()
        ..name = 'NYT Technology'
        ..url = 'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml'
        ..folderId = f1Id
        ..sortOrder = 0;
      final feed2 = LocalFeedItem()
        ..name = 'NASA Video'
        ..url = 'https://www.nasa.gov/rss/dyn/twan_vodcast.rss'
        ..folderId = f1Id
        ..sortOrder = 1;
      final feed3 = LocalFeedItem()
        ..name = 'NPR Podcast'
        ..url = 'https://feeds.npr.org/500005/podcast.xml'
        ..folderId = f2Id
        ..sortOrder = 0;
      final feed4 = LocalFeedItem()
        ..name = 'The Verge'
        ..url = 'https://www.theverge.com/rss/index.xml'
        ..folderId = null
        ..sortOrder = 0;

      final feeds = [feed1, feed2, feed3, feed4];
      for (var f in feeds) {
        final id = await _feedsBox.add(f);
        f.id = id;
        await f.save();
      }
    }
  }

  Future<List<LocalFeedFolder>> getFolders() async {
    final list = _foldersBox.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<List<LocalFeedItem>> getFeeds() async {
    final list = _feedsBox.values.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<void> saveFolder(LocalFeedFolder folder) async {
    if (folder.isInBox) {
      await folder.save();
    } else {
      final id = await _foldersBox.add(folder);
      folder.id = id;
      await folder.save();
    }
  }

  Future<void> saveFeed(LocalFeedItem feed) async {
    if (feed.isInBox) {
      await feed.save();
    } else {
      final id = await _feedsBox.add(feed);
      feed.id = id;
      await feed.save();
    }
  }

  Future<void> saveFeeds(List<LocalFeedItem> feeds) async {
    for (var f in feeds) {
      await saveFeed(f);
    }
  }

  Future<void> saveFeedEntry(SavedFeedEntry entry) async {
    // Check if it exists and we are just updating
    final existing = _savedEntriesBox.values
        .where((e) => e.entryId == entry.entryId)
        .firstOrNull;
    if (existing != null) {
      // Overwrite the existing
      entry.isarId = existing.isarId;
      await _savedEntriesBox.put(existing.key, entry);
    } else {
      final id = await _savedEntriesBox.add(entry);
      entry.isarId = id;
      await entry.save();
    }
  }

  Future<void> deleteFeedEntry(String entryId) async {
    final existingKey = _savedEntriesBox.values
        .where((e) => e.entryId == entryId)
        .firstOrNull
        ?.key;
    if (existingKey != null) {
      await _savedEntriesBox.delete(existingKey);
    }
  }

  Future<List<SavedFeedEntry>> getSavedEntries(
      String feedUrl, String status) async {
    return _savedEntriesBox.values
        .where((e) => e.feedUrl == feedUrl && e.status == status)
        .toList();
  }

  Future<List<String>> getAllSavedEntryIds(String feedUrl) async {
    return _savedEntriesBox.values
        .where((e) => e.feedUrl == feedUrl)
        .map((e) => e.entryId)
        .toList();
  }
}

// Global instance for simple state injection
final localDb = LocalDatabase();
