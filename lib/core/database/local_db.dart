import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../hive_registrar.g.dart';
import '../../features/feeds/data/models/local_feed_folder.dart';
import '../../features/feeds/data/models/local_feed_item.dart';
import '../../features/feeds/data/models/saved_feed_entry.dart';
import '../../features/feeds/data/models/third_party_server.dart';
import '../../features/feeds/data/models/downloaded_media.dart';

class LocalDatabase {
  late Box<LocalFeedFolder> _foldersBox;
  late Box<LocalFeedItem> _feedsBox;
  late Box<SavedFeedEntry> _savedEntriesBox;
  late Box<ThirdPartyServer> _thirdPartyServersBox;
  late Box<String> _feedXmlCacheBox;
  late Box<DownloadedMedia> _downloadsBox;
  late Box<String> _settingsBox;
  late Box<bool> _readEntriesBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register the generated adapters
    Hive.registerAdapters();

    _foldersBox = await Hive.openBox<LocalFeedFolder>('folders');
    _feedsBox = await Hive.openBox<LocalFeedItem>('feeds');
    _savedEntriesBox = await Hive.openBox<SavedFeedEntry>('saved_entries');
    _thirdPartyServersBox =
        await Hive.openBox<ThirdPartyServer>('third_party_servers');
    _feedXmlCacheBox = await Hive.openBox<String>('feed_xml_cache');
    _downloadsBox = await Hive.openBox<DownloadedMedia>('downloads');
    _settingsBox = await Hive.openBox<String>('app_settings');
    _readEntriesBox = await Hive.openBox<bool>('read_entries');

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
        ..name = 'Hacker News'
        ..url = 'https://news.ycombinator.com/rss'
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
    final existingKey = _savedEntriesBox.values
        .where((e) => e.entryId == entry.entryId)
        .firstOrNull
        ?.key;
    if (existingKey != null) {
      await _savedEntriesBox.put(existingKey, entry);
    } else {
      await _savedEntriesBox.add(entry);
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
      String? feedUrl, String status) async {
    if (feedUrl == null) {
      return _savedEntriesBox.values.where((e) => e.status == status).toList();
    }
    return _savedEntriesBox.values
        .where((e) => e.feedUrl == feedUrl && e.status == status)
        .toList();
  }

  Future<List<String>> getAllSavedEntryIds(String feedUrl) async {
    // We return ALL saved entry IDs regardless of feedUrl so that if an article
    // appears in multiple feeds or slightly different urls, it remains hidden.
    return _savedEntriesBox.values.map((e) => e.entryId).toList();
  }

  // --- Third Party Servers ---

  Future<List<ThirdPartyServer>> getThirdPartyServers() async {
    return _thirdPartyServersBox.values.toList();
  }

  Future<void> saveThirdPartyServer(ThirdPartyServer server) async {
    if (server.isInBox) {
      await server.save();
    } else {
      await _thirdPartyServersBox.put(server.id, server);
    }
  }

  Future<void> deleteThirdPartyServer(String id) async {
    await _thirdPartyServersBox.delete(id);
  }

  Future<String> getProxyUrl(String originalUrl) async {
    try {
      final uri = Uri.parse(originalUrl);
      var domain = uri.host.toLowerCase();
      if (domain.isEmpty) return originalUrl;

      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }

      // 1. Pre-Check for Existing RSS
      if (originalUrl.endsWith('.rss') ||
          originalUrl.endsWith('.atom') ||
          originalUrl.endsWith('.xml')) {
        return originalUrl;
      }

      final path = uri.path;
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      // 2. Native Interception (No Proxy Needed)
      if (domain == 'reddit.com' || domain == 'old.reddit.com') {
        if (path.startsWith('/r/') || path.startsWith('/user/')) {
          final cleanPath =
              path.endsWith('/') ? path.substring(0, path.length - 1) : path;
          return 'https://$domain$cleanPath.rss';
        }
      } else if (domain == 'medium.com' || domain.endsWith('.medium.com')) {
        if (domain == 'medium.com' &&
            pathSegments.length == 1 &&
            pathSegments[0].startsWith('@')) {
          return 'https://$domain/feed/${pathSegments[0]}';
        } else if (domain.endsWith('.medium.com')) {
          return 'https://$domain/feed';
        }
      } else if (domain == 'github.com') {
        if (pathSegments.length == 3 && pathSegments[2] == 'releases') {
          return 'https://$domain/${pathSegments[0]}/${pathSegments[1]}/releases.atom';
        } else if (pathSegments.length >= 3 && pathSegments[2] == 'commits') {
          final cleanPath =
              path.endsWith('/') ? path.substring(0, path.length - 1) : path;
          return 'https://$domain$cleanPath.atom';
        }
      }

      // 3. Server Routing (yt-dlp vs RSSHub)
      final servers = await getThirdPartyServers();

      // Separate servers by type
      final ytDlpServers =
          servers.where((s) => s.serverType == 'ytdlp').toList();
      final rssHubServers =
          servers.where((s) => s.serverType == 'rsshub').toList();

      // Check for yt-dlp (YouTube)
      if (domain == 'youtube.com' || domain == 'youtu.be') {
        if (ytDlpServers.isNotEmpty) {
          final server = ytDlpServers.first;
          final proxyBaseUrl = server.url.endsWith('/')
              ? server.url.substring(0, server.url.length - 1)
              : server.url;
          return '$proxyBaseUrl/feed?url=${Uri.encodeComponent(originalUrl)}';
        }
      }

      // Check for RSSHub (Twitter/X and Mastodon)
      if (rssHubServers.isNotEmpty) {
        final server = rssHubServers.first;
        final proxyBaseUrl = server.url.endsWith('/')
            ? server.url.substring(0, server.url.length - 1)
            : server.url;

        // Twitter/X Route
        if (domain == 'twitter.com' || domain == 'x.com') {
          if (pathSegments.isNotEmpty) {
            final username = pathSegments.first;
            return '$proxyBaseUrl/twitter/user/$username';
          }
        }

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
      }
    } catch (_) {
      // If parsing fails, just return original
    }
    return originalUrl;
  }

  // --- Feed Cache ---

  Future<String?> getCachedFeedXml(String url) async {
    return _feedXmlCacheBox.get(safeKey(url));
  }

  Future<void> saveCachedFeedXml(String url, String xml) async {
    await _feedXmlCacheBox.put(safeKey(url), xml);
  }

  // --- Downloads ---

  String safeKey(String key) {
    if (key.length <= 200) return key;
    return md5.convert(utf8.encode(key)).toString();
  }

  Future<DownloadedMedia?> getDownload(String url) async {
    return _downloadsBox.get(safeKey(url));
  }

  Future<void> saveDownload(DownloadedMedia media) async {
    await _downloadsBox.put(safeKey(media.url), media);
  }

  Future<void> deleteDownload(String url) async {
    await _downloadsBox.delete(safeKey(url));
  }

  List<DownloadedMedia> getAllDownloads() {
    return _downloadsBox.values.toList();
  }

  ValueListenable<Box<DownloadedMedia>> getDownloadsListenable() {
    return _downloadsBox.listenable();
  }

  // --- App Settings ---

  bool get isDarkMode {
    final val = _settingsBox.get('is_dark_mode');
    return val == null || val == 'true';
  }

  Future<void> setDarkMode(bool isDark) async {
    await _settingsBox.put('is_dark_mode', isDark.toString());
  }

  String get mercuryParserUrl {
    return _settingsBox.get('mercury_parser_url') ?? 'http://localhost:3000';
  }

  Future<void> setMercuryParserUrl(String url) async {
    await _settingsBox.put('mercury_parser_url', url);
  }

  double get readerFontSize {
    final val = _settingsBox.get('reader_font_size');
    return val != null ? double.tryParse(val) ?? 18.0 : 18.0;
  }

  Future<void> setReaderFontSize(double size) async {
    await _settingsBox.put('reader_font_size', size.toString());
  }

  String get readerFontFamily {
    return _settingsBox.get('reader_font_family') ?? 'sans-serif';
  }

  Future<void> setReaderFontFamily(String family) async {
    await _settingsBox.put('reader_font_family', family);
  }

  // --- Read Entries ---

  Future<void> markEntryAsRead(String entryId) async {
    await _readEntriesBox.put(safeKey(entryId), true);
  }

  bool isEntryRead(String entryId) {
    return _readEntriesBox.get(safeKey(entryId), defaultValue: false) ?? false;
  }

  Set<String> getAllReadEntryIds() {
    return _readEntriesBox.keys.cast<String>().toSet();
  }
}

// Global instance for simple state injection
final localDb = LocalDatabase();
