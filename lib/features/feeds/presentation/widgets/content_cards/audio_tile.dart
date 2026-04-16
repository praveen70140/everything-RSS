import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/media/media_provider.dart';
import 'download_button.dart';
import 'feed_card_styles.dart';

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

    void togglePlay() {
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
      onTap: isLoading ? null : togglePlay,
      child: Padding(
        padding: FeedCardStyles.mediaTextPadding,
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
                      fontSize: FeedCardStyles.denseTitleSize,
                      fontWeight: FontWeight.w800,
                      color:
                          isThisAudioPlaying ? AppColors.blue : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    author,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.subtext1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            DownloadButton(
              url: audioUrl,
              title: title,
              mediaType: 'audio',
            ),
            const SizedBox(width: 16),
            if (isLoading)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.blue,
                  strokeWidth: 2.5,
                ),
              )
            else if (isThisAudioPlaying)
              Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: AppColors.blue,
                size: 40,
              )
            else
              Icon(
                Icons.play_circle_outline,
                color: AppColors.overlay0,
                size: 40,
              ),
          ],
        ),
      ),
    );
  }
}
