import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/feeds/data/models/local_feed_folder.dart';
import '../../features/feeds/data/models/local_feed_item.dart';
import '../../features/feeds/data/models/saved_feed_entry.dart';

class LocalDatabase {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [LocalFeedFolderSchema, LocalFeedItemSchema, SavedFeedEntrySchema],
      directory: dir.path,
    );
    
    // Add default mock data if completely empty
    if (await isar.localFeedFolders.count() == 0 && await isar.localFeedItems.count() == 0) {
      await isar.writeTxn(() async {
        final f1 = LocalFeedFolder()..name = 'NEWS & MEDIA'..isExpanded = true..sortOrder = 0;
        final f2 = LocalFeedFolder()..name = 'PODCASTS'..isExpanded = false..sortOrder = 1;
        await isar.localFeedFolders.putAll([f1, f2]);

        await isar.localFeedItems.putAll([
          LocalFeedItem()..name = 'NYT Technology'..url = 'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml'..folderId = f1.id..sortOrder = 0,
          LocalFeedItem()..name = 'NASA Video'..url = 'https://www.nasa.gov/rss/dyn/twan_vodcast.rss'..folderId = f1.id..sortOrder = 1,
          LocalFeedItem()..name = 'NPR Podcast'..url = 'https://feeds.npr.org/500005/podcast.xml'..folderId = f2.id..sortOrder = 0,
          LocalFeedItem()..name = 'The Verge'..url = 'https://www.theverge.com/rss/index.xml'..folderId = null..sortOrder = 0,
        ]);
      });
    }
  }

  Future<List<LocalFeedFolder>> getFolders() async {
    return await isar.localFeedFolders.where().sortBySortOrder().findAll();
  }

  Future<List<LocalFeedItem>> getFeeds() async {
    return await isar.localFeedItems.where().sortBySortOrder().findAll();
  }

  Future<void> saveFolder(LocalFeedFolder folder) async {
    await isar.writeTxn(() async {
      await isar.localFeedFolders.put(folder);
    });
  }

  Future<void> saveFeed(LocalFeedItem feed) async {
    await isar.writeTxn(() async {
      await isar.localFeedItems.put(feed);
    });
  }

  Future<void> saveFeeds(List<LocalFeedItem> feeds) async {
    await isar.writeTxn(() async {
      await isar.localFeedItems.putAll(feeds);
    });
  }

  Future<void> saveFeedEntry(SavedFeedEntry entry) async {
    await isar.writeTxn(() async {
      await isar.savedFeedEntrys.put(entry);
    });
  }

  Future<void> deleteFeedEntry(String entryId) async {
    await isar.writeTxn(() async {
      await isar.savedFeedEntrys.where().entryIdEqualTo(entryId).deleteAll();
    });
  }

  Future<List<SavedFeedEntry>> getSavedEntries(String feedUrl, String status) async {
    return await isar.savedFeedEntrys
        .where()
        .filter()
        .feedUrlEqualTo(feedUrl)
        .and()
        .statusEqualTo(status)
        .findAll();
  }

  Future<List<String>> getAllSavedEntryIds(String feedUrl) async {
    final entries = await isar.savedFeedEntrys
        .where()
        .filter()
        .feedUrlEqualTo(feedUrl)
        .findAll();
    return entries.map((e) => e.entryId).toList();
  }
}

// Global instance for simple state injection
final localDb = LocalDatabase();
