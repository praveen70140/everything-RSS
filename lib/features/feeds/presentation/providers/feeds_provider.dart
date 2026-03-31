import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/feed_entry.dart';
import '../../data/models/saved_feed_entry.dart';
import '../../data/repositories/rss_service.dart';
import '../../../../core/database/local_db.dart';

class FeedsState {
  final List<FeedEntry> entries;
  final Set<String> hiddenEntryIds;
  final String? currentFeedUrl;
  final String currentFeedName;

  FeedsState({
    required this.entries,
    required this.hiddenEntryIds,
    this.currentFeedUrl,
    this.currentFeedName = 'ALL FEEDS',
  });

  FeedsState copyWith({
    List<FeedEntry>? entries,
    Set<String>? hiddenEntryIds,
    String? currentFeedUrl,
    String? currentFeedName,
  }) {
    return FeedsState(
      entries: entries ?? this.entries,
      hiddenEntryIds: hiddenEntryIds ?? this.hiddenEntryIds,
      currentFeedUrl: currentFeedUrl ?? this.currentFeedUrl,
      currentFeedName: currentFeedName ?? this.currentFeedName,
    );
  }
}

class FeedsNotifier extends AsyncNotifier<FeedsState> {
  final RssService _rssService = RssService();

  @override
  Future<FeedsState> build() async {
    return _fetchFeeds(null, null, forceRefresh: false);
  }

  Future<void> loadFeed(String? url,
      {String? feedName, bool forceRefresh = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _fetchFeeds(url, feedName, forceRefresh: forceRefresh));
  }

  Future<FeedsState> _fetchFeeds(String? url, String? feedName,
      {bool forceRefresh = false}) async {
    List<FeedEntry> allEntries = [];
    Set<String> hiddenIds = {};

    if (url == null) {
      final feeds = await localDb.getFeeds();
      if (feeds.isEmpty) {
        return FeedsState(
          entries: [],
          hiddenEntryIds: {},
          currentFeedUrl: null,
          currentFeedName: 'ALL FEEDS',
        );
      }

      final futures = feeds.map((feed) async {
        try {
          final fetchUrl = await localDb.getProxyUrl(feed.url);
          final entries = await _rssService.fetchFeed(fetchUrl,
              forceRefresh: forceRefresh,
              feedName: feed.name,
              originalUrl: feed.url);
          final ids = await localDb.getAllSavedEntryIds(feed.url);
          return {'entries': entries, 'hiddenIds': ids};
        } catch (e) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      for (var res in results) {
        if (res != null) {
          allEntries.addAll(res['entries'] as List<FeedEntry>);
          hiddenIds.addAll(res['hiddenIds'] as Iterable<String>);
        }
      }

      allEntries.sort((a, b) {
        if (a.pubDate == null && b.pubDate == null) return 0;
        if (a.pubDate == null) return 1;
        if (b.pubDate == null) return -1;
        return b.pubDate!.compareTo(a.pubDate!);
      });
    } else {
      final fetchUrl = await localDb.getProxyUrl(url);
      allEntries = await _rssService.fetchFeed(fetchUrl,
          forceRefresh: forceRefresh, feedName: feedName, originalUrl: url);
      final ids = await localDb.getAllSavedEntryIds(url);
      hiddenIds = ids.toSet();
    }

    return FeedsState(
      entries: allEntries,
      hiddenEntryIds: hiddenIds,
      currentFeedUrl: url,
      currentFeedName: feedName ?? (url == null ? 'ALL FEEDS' : 'FEED'),
    );
  }

  void hideEntry(String id) {
    if (state.value != null) {
      final newHidden = Set<String>.from(state.value!.hiddenEntryIds)..add(id);
      state = AsyncValue.data(state.value!.copyWith(hiddenEntryIds: newHidden));
    }
  }

  void restoreEntry(String id) {
    if (state.value != null) {
      final newHidden = Set<String>.from(state.value!.hiddenEntryIds)
        ..remove(id);
      state = AsyncValue.data(state.value!.copyWith(hiddenEntryIds: newHidden));
    }
  }

  Future<void> saveEntryToDb(FeedEntry entry, String status) async {
    final savedEntry = SavedFeedEntry()
      ..feedUrl = entry.feedUrl ?? state.value?.currentFeedUrl ?? ''
      ..entryId = entry.id
      ..title = entry.title
      ..subtitle = entry.subtitle
      ..mediaType = entry.mediaType.toString()
      ..mediaUrl = entry.mediaUrl
      ..status = status;

    await localDb.saveFeedEntry(savedEntry);
  }

  Future<void> markAllAsRead() async {
    if (state.value == null) return;
    final currentState = state.value!;

    final visibleEntries = currentState.entries
        .where((e) => !currentState.hiddenEntryIds.contains(e.id))
        .toList();
    for (var entry in visibleEntries) {
      await localDb.markEntryAsRead(entry.id);
    }
    // Force a rebuild by re-emitting state
    state = AsyncValue.data(currentState.copyWith());
  }
}

final feedsProvider = AsyncNotifierProvider<FeedsNotifier, FeedsState>(() {
  return FeedsNotifier();
});
