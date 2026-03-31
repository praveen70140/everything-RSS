import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/media/media_provider.dart';
import '../../data/models/feed_entry.dart';
import '../widgets/feeds_drawer.dart';
import '../widgets/content_cards/photo_card.dart';
import '../widgets/content_cards/video_card.dart';
import '../widgets/content_cards/article_tile.dart';
import '../widgets/content_cards/audio_tile.dart';
import '../widgets/content_cards/dense_article_tile.dart';
import '../widgets/skeleton/skeleton_feed_list.dart';
import '../providers/feeds_provider.dart';
import '../../../../core/database/local_db.dart';
import 'article_detail_page.dart';

class FeedsPage extends ConsumerStatefulWidget {
  const FeedsPage({super.key});

  @override
  ConsumerState<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends ConsumerState<FeedsPage> {
  final ScrollController _scrollController = ScrollController();
  int _visibleLimit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(feedsProvider).value;
    if (state == null) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (_visibleLimit < state.entries.length) {
        setState(() {
          _visibleLimit += 20;
        });
      }
    }
  }

  void _handleDismiss(FeedEntry entry, String status) {
    final notifier = ref.read(feedsProvider.notifier);

    // Optimistic hide
    notifier.hideEntry(entry.id);

    // Show undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content:
                Text('Moved to ${status == 'archive' ? 'Archive' : 'To-Do'}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.blue,
              onPressed: () {
                notifier.restoreEntry(entry.id);
              },
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) {
        // If not undone, save to DB
        notifier.saveEntryToDb(entry, status);
      }
    });
  }

  Widget _buildContentItem(List<FeedEntry> entries, int index, bool isDense) {
    final entry = entries[index];
    final bool isRead = localDb.isEntryRead(entry.id);
    final state = ref.read(feedsProvider).value;

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
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailPage(
                      entries: entries,
                      initialIndex: index,
                    ),
                  ),
                );
              }
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
                state?.currentFeedUrl ??
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
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailPage(
                  entries: entries,
                  initialIndex: index,
                ),
              ),
            );
          }
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
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailPage(
                  entries: entries,
                  initialIndex: index,
                ),
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedsStateAsync = ref.watch(feedsProvider);
    final isMediaPlaying = ref.watch(mediaStateProvider).mediaItem != null;

    final feedName = feedsStateAsync.value?.currentFeedName ?? 'ALL FEEDS';
    final currentFeedUrl = feedsStateAsync.value?.currentFeedUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          feedName,
          style: GoogleFonts.epilogue(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: () {
              ref.read(feedsProvider.notifier).markAllAsRead();
            },
            tooltip: 'Mark All As Read',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(feedsProvider.notifier)
                  .loadFeed(currentFeedUrl, forceRefresh: true);
              setState(() => _visibleLimit = 20);
            },
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
          setState(() => _visibleLimit = 20);
          ref.read(feedsProvider.notifier).loadFeed(url, feedName: feedName);
        },
      ),
      body: feedsStateAsync.when(
        data: (state) => _buildBody(state, isMediaPlaying),
        loading: () => const SkeletonFeedList(),
        error: (error, stack) => _buildError(error.toString()),
      ),
    );
  }

  Widget _buildError(String error) {
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
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.subtext1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FeedsState state, bool isMediaPlaying) {
    if (state.entries.isEmpty) {
      return Center(
        child: Text(
          'No items found in feed.',
          style: TextStyle(color: AppColors.subtext1, fontSize: 16),
        ),
      );
    }

    final visibleEntries = state.entries
        .where((e) => !state.hiddenEntryIds.contains(e.id))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(feedsProvider.notifier)
            .loadFeed(state.currentFeedUrl, forceRefresh: true);
        setState(() => _visibleLimit = 20);
      },
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
                _handleDismiss(entry, 'archive');
              } else if (direction == DismissDirection.startToEnd) {
                _handleDismiss(entry, 'todo');
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
