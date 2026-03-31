import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/media/global_video_player_provider.dart';
import 'download_button.dart';

class VideoCard extends ConsumerWidget {
  final String videoUrl;
  final String title;
  final String? imageUrl;
  final String? author;

  const VideoCard({
    super.key,
    required this.videoUrl,
    required this.title,
    this.imageUrl,
    this.author,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: AppColors.crust,
            child: InkWell(
              onTap: () {
                ref.read(globalVideoProvider.notifier).playVideo(
                      url: videoUrl,
                      title: title,
                      author: author,
                      imageUrl: imageUrl,
                    );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: AppColors.surface0),
                      errorWidget: (context, url, error) =>
                          Container(color: AppColors.surface0),
                    )
                  else
                    Container(color: AppColors.surface0),

                  // Dark Overlay
                  Container(color: Colors.black.withOpacity(0.2)),

                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: AppColors.base,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.epilogue(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(width: 8),
              DownloadButton(
                url: videoUrl,
                title: title,
                mediaType: 'video',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
