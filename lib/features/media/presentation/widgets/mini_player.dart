import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/media/media_provider.dart';
import '../pages/full_screen_player.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaStateProvider);
    final mediaItem = mediaState.mediaItem;

    if (mediaItem == null) return SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const FullScreenPlayer(),
        );
      },
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: mediaItem.artUri != null
                  ? CachedNetworkImage(
                      imageUrl: mediaItem.artUri.toString(),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Icon(Icons.music_note, size: 32),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child:
                          Icon(Icons.music_note, color: Colors.white54),
                    ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mediaItem.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (mediaItem.album != null) ...[
                    SizedBox(height: 2),
                    Text(
                      mediaItem.album!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (mediaState.isBuffering)
              Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(
                icon: Icon(mediaState.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
                iconSize: 32,
                onPressed: () {
                  final notifier = ref.read(mediaStateProvider.notifier);
                  if (mediaState.isPlaying) {
                    notifier.pause();
                  } else {
                    notifier.play();
                  }
                },
              ),
            IconButton(
              icon: Icon(Icons.close_rounded),
              onPressed: () => ref.read(mediaStateProvider.notifier).stop(),
            ),
          ],
        ),
      ),
    );
  }
}
