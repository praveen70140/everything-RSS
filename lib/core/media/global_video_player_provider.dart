import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../database/local_db.dart';
import 'sponsor_block_service.dart';
import 'media_provider.dart';

class VideoPlayerState {
  final VideoPlayerController? videoController;
  final ChewieController? chewieController;
  final String? currentUrl;
  final String? title;
  final String? author;
  final String? imageUrl;
  final bool isLoading;
  final bool isPlaying;

  VideoPlayerState({
    this.videoController,
    this.chewieController,
    this.currentUrl,
    this.title,
    this.author,
    this.imageUrl,
    this.isLoading = false,
    this.isPlaying = false,
  });

  VideoPlayerState copyWith({
    VideoPlayerController? videoController,
    ChewieController? chewieController,
    String? currentUrl,
    String? title,
    String? author,
    String? imageUrl,
    bool? isLoading,
    bool? isPlaying,
  }) {
    return VideoPlayerState(
      videoController: videoController ?? this.videoController,
      chewieController: chewieController ?? this.chewieController,
      currentUrl: currentUrl ?? this.currentUrl,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class GlobalVideoNotifier extends Notifier<VideoPlayerState> {
  List<SponsorSegment> _sponsorSegments = [];
  bool _isSkipping = false;

  @override
  VideoPlayerState build() {
    return VideoPlayerState();
  }

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
    if (state.videoController == null || _isSkipping) return;

    // Update play state
    if (state.videoController!.value.isPlaying != state.isPlaying) {
      state = state.copyWith(isPlaying: state.videoController!.value.isPlaying);
    }

    final currentPosition =
        state.videoController!.value.position.inSeconds.toDouble();

    for (final segment in _sponsorSegments) {
      if (currentPosition >= segment.start && currentPosition < segment.end) {
        _isSkipping = true;
        state.videoController!
            .seekTo(Duration(seconds: segment.end.toInt() + 1))
            .then((_) {
          _isSkipping = false;
        });
        break;
      }
    }
  }

  Future<void> playVideo({
    required String url,
    required String title,
    String? author,
    String? imageUrl,
  }) async {
    // If it's already playing this exact video, do nothing
    if (state.currentUrl == url) return;

    // Stop current video
    await stop();

    state = VideoPlayerState(
      isLoading: true,
      currentUrl: url,
      title: title,
      author: author,
      imageUrl: imageUrl,
    );

    VideoPlayerController controller;

    final download = await localDb.getDownload(url);
    if (download != null && download.status == 'completed') {
      final file = File(download.localPath);
      if (await file.exists()) {
        controller = VideoPlayerController.file(file);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    try {
      final videoId = _extractVideoId(url);
      if (videoId != null) {
        _sponsorSegments = await SponsorBlockService.getSegments(videoId);
      } else {
        _sponsorSegments = [];
      }

      await controller.initialize();
      controller.addListener(_videoListener);

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        showOptions: false,
      );

      state = state.copyWith(
        videoController: controller,
        chewieController: chewie,
        isLoading: false,
        isPlaying: true,
      );

      // Setup PiP
      ref.read(pipVideoProvider.notifier).setController(controller);
    } catch (e) {
      debugPrint("Error initializing global video: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void togglePlay() {
    if (state.videoController != null) {
      if (state.videoController!.value.isPlaying) {
        state.videoController!.pause();
      } else {
        state.videoController!.play();
      }
    }
  }

  Future<void> stop() async {
    state.videoController?.removeListener(_videoListener);
    await state.videoController?.pause();
    await state.videoController?.dispose();
    state.chewieController?.dispose();
    _sponsorSegments = [];
    ref.read(pipVideoProvider.notifier).setController(null);
    state = VideoPlayerState();
  }
}

final globalVideoProvider =
    NotifierProvider<GlobalVideoNotifier, VideoPlayerState>(() {
  return GlobalVideoNotifier();
});

// Create a generic media player type to unify audio and video checks
enum ActiveMediaType { none, audio, video }

final activeMediaTypeProvider = Provider<ActiveMediaType>((ref) {
  final videoState = ref.watch(globalVideoProvider);
  if (videoState.currentUrl != null) return ActiveMediaType.video;

  final audioState = ref.watch(mediaStateProvider);
  if (audioState.mediaItem != null) return ActiveMediaType.audio;

  return ActiveMediaType.none;
});
