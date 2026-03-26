import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/media/media_provider.dart';

class FullScreenPlayer extends ConsumerWidget {
  const FullScreenPlayer({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaStateProvider);
    final mediaItem = mediaState.mediaItem;

    if (mediaItem == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 24),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Artwork
                  Hero(
                    tag: 'artwork_${mediaItem.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: mediaItem.artUri != null
                              ? CachedNetworkImage(
                                  imageUrl: mediaItem.artUri.toString(),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.music_note,
                                      size: 80, color: Colors.white54),
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Title and Author
                  Column(
                    children: [
                      Text(
                        mediaItem.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mediaItem.album ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Progress Bar
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor:
                              Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Colors.grey[800],
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: mediaState.position.inSeconds.toDouble().clamp(
                              0.0, mediaState.duration.inSeconds.toDouble()),
                          max: mediaState.duration.inSeconds.toDouble() > 0
                              ? mediaState.duration.inSeconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            ref
                                .read(mediaStateProvider.notifier)
                                .seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(mediaState.position),
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                            Text(
                              '-${_formatDuration(mediaState.duration - mediaState.position)}',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Speed Control
                      TextButton(
                        onPressed: () {
                          final currentSpeed = mediaState.speed;
                          final nextSpeed =
                              currentSpeed >= 2.0 ? 1.0 : currentSpeed + 0.25;
                          ref
                              .read(mediaStateProvider.notifier)
                              .setSpeed(nextSpeed);
                        },
                        child: Text('${mediaState.speed}x',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),

                      // Rewind 15s
                      IconButton(
                        icon: const Icon(Icons
                            .replay_10_rounded), // 15 doesn't exist natively, use replay_10
                        iconSize: 36,
                        onPressed: () =>
                            ref.read(mediaStateProvider.notifier).rewind(),
                      ),

                      // Play/Pause
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: IconButton(
                          icon: Icon(mediaState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                          iconSize: 48,
                          color: Colors.white,
                          onPressed: () {
                            if (mediaState.isPlaying) {
                              ref.read(mediaStateProvider.notifier).pause();
                            } else {
                              ref.read(mediaStateProvider.notifier).play();
                            }
                          },
                        ),
                      ),

                      // Fast Forward 15s
                      IconButton(
                        icon: const Icon(Icons
                            .forward_10_rounded), // Fast forward equivalent
                        iconSize: 36,
                        onPressed: () =>
                            ref.read(mediaStateProvider.notifier).fastForward(),
                      ),

                      // More options / AirPlay placeholder
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded),
                        iconSize: 28,
                        color: Colors.grey[400],
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
