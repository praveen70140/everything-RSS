import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
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

class FeedsPage extends StatefulWidget {
  const FeedsPage({super.key});

  @override
  State<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends State<FeedsPage> {
  final RssService _rssService = RssService();
  List<FeedEntry> _entries = [];
  Set<String> _hiddenEntryIds =
      {}; // Local state to hide items removed during this session
  bool _isLoading = true;
  String? _error;

  String _currentFeedUrl =
      'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml';

  @override
  void initState() {
    super.initState();
    _loadFeed(_currentFeedUrl);
  }

  Future<void> _loadFeed(String url) async {
    setState(() {
      _currentFeedUrl = url;
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await _rssService.fetchFeed(url);
      final hiddenIds = await localDb.getAllSavedEntryIds(url);

      setState(() {
        _entries = entries;
        _hiddenEntryIds = hiddenIds.toSet();
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
      ..feedUrl = _currentFeedUrl
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

  Widget _buildContentItem(FeedEntry entry, bool isDense) {
    switch (entry.mediaType) {
      case MediaType.image:
        if (entry.mediaUrl != null) {
          return PhotoCard(
            imageUrl: entry.mediaUrl!,
            title: entry.title,
          );
        }
        break;
      case MediaType.video:
        if (entry.mediaUrl != null) {
          return VideoCard(
            videoUrl: entry.mediaUrl!,
            title: entry.title,
          );
        }
        break;
      case MediaType.audio:
        if (entry.mediaUrl != null) {
          return AudioTile(
            audioUrl: entry.mediaUrl!,
            title: entry.title,
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
      );
    } else {
      return ArticleTile(
        title: entry.title,
        subtitle: entry.subtitle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FEEDS',
          style: GoogleFonts.epilogue(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadFeed(_currentFeedUrl),
            tooltip: 'Refresh Feed',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.surface1, height: 1.0),
        ),
      ),
      drawer: FeedsDrawer(
        onFeedSelected: (url) {
          Navigator.pop(context); // Close the drawer
          _loadFeed(url); // Load the selected feed
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
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
              const Icon(Icons.error_outline, color: AppColors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load feed',
                style: GoogleFonts.epilogue(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.subtext1),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'No items found in feed.',
          style: TextStyle(color: AppColors.subtext1, fontSize: 16),
        ),
      );
    }

    final visibleEntries =
        _entries.where((e) => !_hiddenEntryIds.contains(e.id)).toList();

    return ListView.separated(
      itemCount: visibleEntries.length,
      separatorBuilder: (context, index) =>
          const Divider(color: AppColors.surface1, height: 1),
      itemBuilder: (context, index) {
        final entry = visibleEntries[index];
        final isDense = index > 5 && entry.mediaType == MediaType.text;

        Widget content = _buildContentItem(entry, isDense);

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
            child: const Row(
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
            child: const Row(
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
    );
  }
}
