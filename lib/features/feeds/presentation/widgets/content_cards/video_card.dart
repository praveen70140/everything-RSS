import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/media/media_provider.dart';
import '../../../../../core/database/local_db.dart';
import '../../../../../core/media/sponsor_block_service.dart';
import 'download_button.dart';

class VideoCard extends ConsumerStatefulWidget {
  final String videoUrl;
  final String title;

  const VideoCard({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  ConsumerState<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<VideoCard> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlayerActive = false;
  bool _isLoading = false;
  List<SponsorSegment> _sponsorSegments = [];
  bool _isSkipping = false;

  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.contains('stream')) {
        final index = pathSegments.indexOf('stream');
        if (index + 1 < pathSegments.length) {
          return pathSegments[index + 1];
        }
      }
    } catch (_) {}
    return null;
  }

  void _videoListener() {
    if (_videoPlayerController == null || _isSkipping) return;

    final currentPosition =
        _videoPlayerController!.value.position.inSeconds.toDouble();

    for (final segment in _sponsorSegments) {
      if (currentPosition >= segment.start && currentPosition < segment.end) {
        _isSkipping = true;
        _videoPlayerController!
            .seekTo(Duration(seconds: segment.end.toInt() + 1))
            .then((_) {
          _isSkipping = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Skipped ${segment.category} segment'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
        break;
      }
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _isPlayerActive = true;
    });

    final download = await localDb.getDownload(widget.videoUrl);
    if (download != null && download.status == 'completed') {
      final file = File(download.localPath);
      if (await file.exists()) {
        _videoPlayerController = VideoPlayerController.file(file);
      } else {
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }
    } else {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    }

    try {
      final videoId = _extractVideoId(widget.videoUrl);
      if (videoId != null) {
        _sponsorSegments = await SponsorBlockService.getSegments(videoId);
      }

      await _videoPlayerController!.initialize();
      _videoPlayerController!.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.blue,
          handleColor: AppColors.blue,
          backgroundColor: AppColors.surface0,
          bufferedColor: AppColors.surface1,
        ),
        allowFullScreen: true,
        showOptions: false,
        customControls: const MaterialControls(
          showPlayButton: true,
        ),
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
          _isPlayerActive = false;
        });
      }
    }
  }

  void _enterPipMode() {
    if (_videoPlayerController == null) return;

    // Set the global provider so the AppShell PipWidget knows which controller to use
    ref.read(pipVideoProvider.notifier).setController(_videoPlayerController);

    // Calculate aspect ratio
    final width = _videoPlayerController!.value.size.width.toInt();
    final height = _videoPlayerController!.value.size.height.toInt();

    int w = width > 0 ? width : 16;
    int h = height > 0 ? height : 9;

    // Android PiP requires aspect ratio between 1:2.39 and 2.39:1
    double ratio = w / h;
    if (ratio > 2.39) {
      w = 239;
      h = 100;
    } else if (ratio < 1 / 2.39) {
      w = 100;
      h = 239;
    }

    SimplePip().enterPipMode(
      aspectRatio: (w, h),
    );
  }

  @override
  void dispose() {
    final pipController = ref.read(pipVideoProvider);
    if (pipController != _videoPlayerController) {
      _videoPlayerController?.removeListener(_videoListener);
      _videoPlayerController?.dispose();
    }
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
                    ? Center(
                        child: CircularProgressIndicator(color: AppColors.blue))
                    : Stack(
                        children: [
                          Chewie(controller: _chewieController!),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: IconButton(
                              icon: Icon(Icons.picture_in_picture_alt_rounded,
                                  color: Colors.white),
                              onPressed: _enterPipMode,
                              tooltip: 'Picture in Picture',
                            ),
                          ),
                        ],
                      ))
                : _buildPlaceholder(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
              SizedBox(width: 8),
              DownloadButton(
                url: widget.videoUrl,
                title: widget.title,
                mediaType: 'video',
              ),
            ],
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
              child: Icon(
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
              child: Text(
                'TAP TO LOAD VIDEO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}
