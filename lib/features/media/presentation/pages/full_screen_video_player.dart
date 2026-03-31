import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/media/global_video_player_provider.dart';

class FullScreenVideoPlayer extends ConsumerWidget {
  const FullScreenVideoPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(globalVideoProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.white, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: videoState.isLoading
                    ? CircularProgressIndicator(color: AppColors.blue)
                    : (videoState.chewieController != null
                        ? Chewie(controller: videoState.chewieController!)
                        : const Text(
                            "No video playing",
                            style: TextStyle(color: Colors.white),
                          )),
              ),
            ),
            if (videoState.title != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoState.title!,
                      style: GoogleFonts.epilogue(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (videoState.author != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        videoState.author!,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
