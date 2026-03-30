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

import '../../data/models/third_party_server.dart';

import 'article_detail_page.dart';

class FeedsPage extends ConsumerStatefulWidget {
  const FeedsPage({super.key});

  @override
  ConsumerState<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends ConsumerState<FeedsPage> {
  final RssService _rssService = RssService();
  List<FeedEntry> _entries = [];
  Set<String> _hiddenEntryIds = {};
  bool _isLoading = true;
  String? _error;

  String _currentFeedUrl =
      'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml';

  @override
  void initState() {
    super.initState();
    _loadFeed(_currentFeedUrl);
  }

  Future<void> _loadFeed(String url, {bool forceRefresh = false}) async {
    setState(() {
      _currentFeedUrl = url;
      _isLoading = true;
      _error = null;
    });

    try {
      final fetchUrl = await localDb.getProxyUrl(url);
      final entries =
          await _rssService.fetchFeed(fetchUrl, forceRefresh: forceRefresh);
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
            author: _currentFeedUrl,
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailPage(entry: entry),
            ),
          );
        },
      );
    } else {
      return ArticleTile(
        title: entry.title,
        subtitle: entry.subtitle,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailPage(entry: entry),
            ),
          );
        },
      );
    }
  }

  Future<void> _showSearchDialog() async {
    final servers = await localDb.getThirdPartyServers();
    if (servers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add a third-party server first.')),
        );
      }
      return;
    }

    if (!mounted) return;

    ThirdPartyServer selectedServer = servers.first;
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Search'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<ThirdPartyServer>(
                  value: selectedServer,
                  isExpanded: true,
                  items: servers.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedServer = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Enter search term...',
                  ),
                  autofocus: true,
                  onSubmitted: (_) {
                    Navigator.pop(context);
                    _performSearch(selectedServer, searchController.text);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performSearch(selectedServer, searchController.text);
                },
                child: const Text('Search'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _performSearch(ThirdPartyServer server, String term) async {
    if (term.isEmpty) return;

    final baseUrl = server.url.endsWith('/')
        ? server.url.substring(0, server.url.length - 1)
        : server.url;
    final searchUrl = '$baseUrl/search?q=${Uri.encodeComponent(term)}';

    // Call load feed with search URL directly. It won't be proxied again because
    // the search domain likely won't match the supported domains exactly as an original URL.
    _loadFeed(searchUrl, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isMediaPlaying = ref.watch(mediaStateProvider).mediaItem != null;

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
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search via Third-Party Server',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
        onFeedSelected: (url) {
          Navigator.pop(context);
          _loadFeed(url);
        },
      ),
      body: _buildBody(isMediaPlaying),
    );
  }

  Widget _buildBody(bool isMediaPlaying) {
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
      padding: EdgeInsets.only(bottom: isMediaPlaying ? 90.0 : 16.0),
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
