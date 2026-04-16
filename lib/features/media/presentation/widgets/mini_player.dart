import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/media/media_provider.dart';
import '../../../../core/media/global_video_player_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/full_screen_player.dart';
import '../pages/full_screen_video_player.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMediaType = ref.watch(activeMediaTypeProvider);

    if (activeMediaType == ActiveMediaType.none) {
      return const SizedBox.shrink();
    }

    if (activeMediaType == ActiveMediaType.video) {
      return _buildVideoMiniPlayer(context, ref);
    }

    return _buildAudioMiniPlayer(context, ref);
  }

  Widget _buildVideoMiniPlayer(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(globalVideoProvider);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.black,
          builder: (context) => const FullScreenVideoPlayer(),
        );
      },
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.mantle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: videoState.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: videoState.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                          Icons.video_library,
                          size: 28,
                          color: AppColors.subtext1),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: AppColors.crust,
                      child:
                          Icon(Icons.video_library, color: AppColors.subtext1, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    videoState.title ?? 'Unknown Video',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (videoState.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      videoState.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.subtext1, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (videoState.isLoading)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              IconButton(
                icon: Icon(videoState.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded),
                iconSize: 32,
                color: AppColors.text,
                tooltip: videoState.isPlaying ? 'Pause' : 'Play',
                onPressed: () {
                  ref.read(globalVideoProvider.notifier).togglePlay();
                },
              ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.overlay0,
              tooltip: 'Close player',
              onPressed: () => ref.read(globalVideoProvider.notifier).stop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMiniPlayer(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaStateProvider);
    final mediaItem = mediaState.mediaItem;

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
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.mantle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: mediaItem!.artUri != null
                  ? CachedNetworkImage(
                      imageUrl: mediaItem.artUri.toString(),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                          Icons.music_note,
                          size: 28,
                          color: AppColors.subtext1),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: AppColors.crust,
                      child: Icon(Icons.music_note, color: AppColors.subtext1, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
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
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (mediaItem.album != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      mediaItem.album!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.subtext1, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (mediaState.isBuffering)
              const Padding(
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
                color: AppColors.text,
                tooltip: mediaState.isPlaying ? 'Pause' : 'Play',
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
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.overlay0,
              tooltip: 'Close player',
              onPressed: () => ref.read(mediaStateProvider.notifier).stop(),
            ),
          ],
        ),
      ),
    );
  }
}
