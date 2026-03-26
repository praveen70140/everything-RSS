import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../../core/theme/app_colors.dart';

class VideoCard extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoCard({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlayerActive = false;
  bool _isLoading = false;

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _isPlayerActive = true;
    });

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true, // Auto-play once the user clicks the placeholder
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0 ? _videoPlayerController!.value.aspectRatio : 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.blue,
          handleColor: AppColors.blue,
          backgroundColor: AppColors.surface0,
          bufferedColor: AppColors.surface1,
        ),
        allowFullScreen: true,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlayerActive = false; // reset on error
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: AppColors.crust,
            child: _isPlayerActive
                ? (_isLoading || _chewieController == null
                    ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
                    : Chewie(controller: _chewieController!))
                : _buildPlaceholder(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Text(
            widget.title,
            style: GoogleFonts.epilogue(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return InkWell(
      onTap: _initializePlayer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // If we had a thumbnail URL, we'd put an Image.network here.
          // For now, a solid surface color works as a clean placeholder.
          Container(color: AppColors.surface0),
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
              child: const Icon(
                Icons.play_arrow,
                color: AppColors.base,
                size: 36,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TAP TO LOAD VIDEO',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}
