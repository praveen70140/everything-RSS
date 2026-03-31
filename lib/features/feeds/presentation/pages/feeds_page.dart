import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/media/media_provider.dart';
import '../../data/models/feed_entry.dart';
import '../../data/repositories/rss_service.dart';
import '../widgets/feeds_drawer.dart';
import '../widgets/content_cards/photo_card.dart';
import '../widgets/content_cards/video_card.dart';
import '../widgets/content_cards/article_tile.dart';
import '../widgets/content_cards/audio_tile.dart';
import '../widgets/content_cards/dense_article_tile.dart';

import '../../data/models/saved_feed_entry.dart';
import '../../../../core/database/local_db.dart';

import 'article_detail_page.dart';

class FeedsPage extends ConsumerStatefulWidget {
  const FeedsPage({super.key});

  @override
  ConsumerState<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends ConsumerState<FeedsPage> {
  final RssService _rssService = RssService();
  final ScrollController _scrollController = ScrollController();
  List<FeedEntry> _entries = [];
  Set<String> _hiddenEntryIds = {};
  bool _isLoading = true;
  String? _error;
  int _visibleLimit = 20;

  String? _currentFeedUrl; // null means 'All Feeds'
  String _currentFeedName = 'ALL FEEDS';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFeed(null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (_visibleLimit < _entries.length) {
        setState(() {
          _visibleLimit += 20;
        });
      }
    }
  }

  Future<void> _loadFeed(String? url,
      {bool forceRefresh = false, String? feedName}) async {
    setState(() {
      _currentFeedUrl = url;
      _currentFeedName = feedName ?? (url == null ? 'ALL FEEDS' : 'FEED');
      _visibleLimit = 20; // Reset limit when feed changes
      if (_entries.isEmpty || forceRefresh == false) {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      List<FeedEntry> allEntries = [];
      Set<String> hiddenIds = {};

      if (url == null) {
        // Load all feeds
        final feeds = await localDb.getFeeds();
        if (feeds.isEmpty) {
          // Fallback if empty to something just to show, though we should probably just show empty state
          setState(() {
            _entries = [];
            _hiddenEntryIds = {};
            _isLoading = false;
          });
          return;
        }

        // Fetch concurrently
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
            print('Error fetching feed ${feed.url}: $e');
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

        // Sort globally by pubDate
        allEntries.sort((a, b) {
          if (a.pubDate == null && b.pubDate == null) return 0;
          if (a.pubDate == null) return 1;
          if (b.pubDate == null) return -1;
          return b.pubDate!.compareTo(a.pubDate!);
        });
      } else {
        // Load single feed
        final fetchUrl = await localDb.getProxyUrl(url);
        allEntries = await _rssService.fetchFeed(fetchUrl,
            forceRefresh: forceRefresh, feedName: feedName, originalUrl: url);
        final ids = await localDb.getAllSavedEntryIds(url);
        hiddenIds = ids.toSet();
      }

      setState(() {
        _entries = allEntries;
        _hiddenEntryIds = hiddenIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEntry(FeedEntry entry, String status) async {
    final savedEntry = SavedFeedEntry()
      ..feedUrl = entry.feedUrl ?? _currentFeedUrl ?? ''
      ..entryId = entry.id
      ..title = entry.title
      ..subtitle = entry.subtitle
      ..mediaType = entry.mediaType.toString()
      ..mediaUrl = entry.mediaUrl
      ..status = status;

    await localDb.saveFeedEntry(savedEntry);

    setState(() {
      _hiddenEntryIds.add(entry.id);
    });
  }

  Widget _buildContentItem(List<FeedEntry> entries, int index, bool isDense) {
    final entry = entries[index];
    final bool isRead = localDb.isEntryRead(entry.id);

    switch (entry.mediaType) {
      case MediaType.image:
        if (entry.mediaUrl != null) {
          return PhotoCard(
            imageUrl: entry.mediaUrl!,
            title: entry.title,
            subtitle: entry.subtitle,
            author: entry.author,
            pubDate: entry.pubDate,
            isRead: isRead,
            onTap: () async {
              await localDb.markEntryAsRead(entry.id);
              setState(() {});
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(
                    entries: entries,
                    initialIndex: index,
                  ),
                ),
              );
            },
          );
        }
        break;
      case MediaType.video:
        if (entry.mediaUrl != null) {
          return VideoCard(
            videoUrl: entry.mediaUrl!,
            title: entry.title,
            imageUrl: entry.imageUrl,
          );
        }
        break;
      case MediaType.audio:
        if (entry.mediaUrl != null) {
          return AudioTile(
            audioUrl: entry.mediaUrl!,
            title: entry.title,
            author: entry.feedName ??
                entry.feedUrl ??
                _currentFeedUrl ??
                'Unknown Feed',
          );
        }
        break;
      case MediaType.text:
      default:
        break;
    }

    if (isDense) {
      return DenseArticleTile(
        title: entry.title,
        subtitle: entry.subtitle,
        author: entry.author,
        pubDate: entry.pubDate,
        isRead: isRead,
        onTap: () async {
          await localDb.markEntryAsRead(entry.id);
          setState(() {});
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailPage(
                entries: entries,
                initialIndex: index,
              ),
            ),
          );
        },
      );
    } else {
      return ArticleTile(
        title: entry.title,
        subtitle: entry.subtitle,
        author: entry.author,
        pubDate: entry.pubDate,
        isRead: isRead,
        onTap: () async {
          await localDb.markEntryAsRead(entry.id);
          setState(() {});
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailPage(
                entries: entries,
                initialIndex: index,
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMediaPlaying = ref.watch(mediaStateProvider).mediaItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentFeedName,
          style: GoogleFonts.epilogue(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _loadFeed(_currentFeedUrl, forceRefresh: true),
            tooltip: 'Refresh Feed',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.surface1, height: 1.0),
        ),
      ),
      drawer: FeedsDrawer(
        onFeedSelected: (url, {feedName}) {
          Navigator.pop(context);
          _loadFeed(url, feedName: feedName);
        },
      ),
      body: _buildBody(isMediaPlaying),
    );
  }

  Widget _buildBody(bool isMediaPlaying) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load feed',
                style: GoogleFonts.epilogue(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.subtext1),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text(
          'No items found in feed.',
          style: TextStyle(color: AppColors.subtext1, fontSize: 16),
        ),
      );
    }

    final visibleEntries =
        _entries.where((e) => !_hiddenEntryIds.contains(e.id)).toList();

    return RefreshIndicator(
      onRefresh: () => _loadFeed(_currentFeedUrl, forceRefresh: true),
      color: AppColors.blue,
      backgroundColor: AppColors.surface0,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: isMediaPlaying ? 90.0 : 16.0),
        itemCount: (visibleEntries.length > _visibleLimit
                ? _visibleLimit
                : visibleEntries.length) +
            (visibleEntries.length > _visibleLimit ? 1 : 0),
        separatorBuilder: (context, index) =>
            Divider(color: AppColors.surface1, height: 1),
        itemBuilder: (context, index) {
          if (index == _visibleLimit) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            );
          }

          final entry = visibleEntries[index];
          final isDense = index > 5 && entry.mediaType == MediaType.text;

          Widget content = _buildContentItem(visibleEntries, index, isDense);

          return Dismissible(
            key: Key(entry.id),
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                _saveEntry(entry, 'archive');
              } else if (direction == DismissDirection.startToEnd) {
                _saveEntry(entry, 'todo');
              }
            },
            background: Container(
              color: AppColors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('TO-DO',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            secondaryBackground: Container(
              color: AppColors.mauve,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('ARCHIVE',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.archive, color: Colors.white),
                ],
              ),
            ),
            child: content,
          );
        },
      ),
    );
  }
}
