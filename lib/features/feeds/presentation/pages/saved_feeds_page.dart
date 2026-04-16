import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/local_db.dart';
import '../../data/models/saved_feed_entry.dart';
import '../../data/models/feed_entry.dart';
import '../widgets/content_cards/photo_card.dart';
import '../widgets/content_cards/video_card.dart';
import '../widgets/content_cards/article_tile.dart';
import '../widgets/content_cards/audio_tile.dart';
import '../widgets/content_cards/dense_article_tile.dart';
import '../widgets/feedback/empty_state.dart';

class SavedFeedsPage extends StatefulWidget {
  final String? feedUrl;
  final String status; // 'archive' or 'todo'
  final String feedName;

  const SavedFeedsPage({
    super.key,
    this.feedUrl,
    required this.status,
    required this.feedName,
  });

  @override
  State<SavedFeedsPage> createState() => _SavedFeedsPageState();
}

class _SavedFeedsPageState extends State<SavedFeedsPage> {
  List<SavedFeedEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries =
        await localDb.getSavedEntries(widget.feedUrl, widget.status);
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeEntry(SavedFeedEntry entry, int index) async {
    setState(() {
      _entries.removeWhere((item) => item.entryId == entry.entryId);
    });

    final label = widget.status == 'archive' ? 'Archive' : 'To do';
    ScaffoldMessenger.of(context).clearSnackBars();
    final reason = await ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text('Removed from $label'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.blue,
              onPressed: () {
                setState(() {
                  final safeIndex = index.clamp(0, _entries.length);
                  _entries.insert(safeIndex, entry);
                });
              },
            ),
          ),
        )
        .closed;

    if (reason != SnackBarClosedReason.action) {
      await localDb.deleteFeedEntry(entry.entryId);
    }
  }

  Widget _buildContentItem(SavedFeedEntry entry, bool isDense, int index) {
    // Map string enum back to MediaType
    MediaType mediaType = MediaType.text;
    if (entry.mediaType == 'MediaType.video') mediaType = MediaType.video;
    if (entry.mediaType == 'MediaType.audio') mediaType = MediaType.audio;
    if (entry.mediaType == 'MediaType.image') mediaType = MediaType.image;

    Widget child;

    switch (mediaType) {
      case MediaType.image:
        if (entry.mediaUrl != null) {
          child = PhotoCard(imageUrl: entry.mediaUrl!, title: entry.title);
        } else {
          child = ArticleTile(title: entry.title, subtitle: entry.subtitle);
        }
        break;
      case MediaType.video:
        if (entry.mediaUrl != null) {
          child = VideoCard(
            videoUrl: entry.mediaUrl!,
            title: entry.title,
          );
        } else {
          child = ArticleTile(title: entry.title, subtitle: entry.subtitle);
        }
        break;
      case MediaType.audio:
        if (entry.mediaUrl != null) {
          child = AudioTile(audioUrl: entry.mediaUrl!, title: entry.title);
        } else {
          child = ArticleTile(title: entry.title, subtitle: entry.subtitle);
        }
        break;
      case MediaType.text:
        if (isDense) {
          child =
              DenseArticleTile(title: entry.title, subtitle: entry.subtitle);
        } else {
          child = ArticleTile(title: entry.title, subtitle: entry.subtitle);
        }
        break;
    }

    return Dismissible(
      key: Key(entry.entryId),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => _removeEntry(entry, index),
      background: Container(
        color: AppColors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: AppColors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titlePrefix = widget.status == 'archive' ? 'Archive' : 'To do';

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        title: Text(
          '$titlePrefix: ${widget.feedName}',
          style: GoogleFonts.epilogue(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.surface1, height: 1.0),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

    if (_entries.isEmpty) {
      final isArchive = widget.status == 'archive';
      return EmptyState(
        icon: isArchive ? Icons.archive_outlined : Icons.watch_later_outlined,
        title: isArchive ? 'Archive is empty' : 'Nothing saved for later',
        message: isArchive
            ? 'Swipe feed items left to move them into the archive.'
            : 'Swipe feed items right to save them for later.',
      );
    }

    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (context, index) =>
          Divider(color: AppColors.surface1, height: 1),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isDense = index > 5 && entry.mediaType == 'MediaType.text';
        return _buildContentItem(entry, isDense, index);
      },
    );
  }
}
