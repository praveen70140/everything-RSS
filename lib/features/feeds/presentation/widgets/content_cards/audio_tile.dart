import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/media/media_provider.dart';
import 'download_button.dart';

class AudioTile extends ConsumerWidget {
  final String audioUrl;
  final String title;
  final String author;
  final String? imageUrl;

  const AudioTile({
    super.key,
    required this.audioUrl,
    required this.title,
    this.author = 'Unknown Author',
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaStateProvider);

    final isThisAudioPlaying = mediaState.mediaItem?.id == audioUrl;
    final isPlaying = isThisAudioPlaying && mediaState.isPlaying;
    final isLoading = isThisAudioPlaying && mediaState.isBuffering;

    void _togglePlay() {
      final notifier = ref.read(mediaStateProvider.notifier);

      if (isThisAudioPlaying) {
        if (isPlaying) {
          notifier.pause();
        } else {
          notifier.play();
        }
      } else {
        notifier.playAudio(
          url: audioUrl,
          title: title,
          author: author,
          imageUrl: imageUrl,
        );
      }
    }

    return InkWell(
      onTap: isLoading ? null : _togglePlay,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isThisAudioPlaying ? AppColors.blue : AppColors.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    author,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            DownloadButton(
              url: audioUrl,
              title: title,
              mediaType: 'audio',
            ),
            SizedBox(width: 16),
            if (isLoading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.blue,
                  strokeWidth: 2,
                ),
              )
            else if (isThisAudioPlaying)
              Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: AppColors.blue,
                size: 36,
              )
            else
              Icon(
                Icons.play_circle_outline,
                color: Colors.grey,
                size: 36,
              ),
          ],
        ),
      ),
    );
  }
}