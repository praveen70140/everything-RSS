import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:video_player/video_player.dart';
import '../database/local_db.dart';

// We'll expose the AudioHandler singleton here.
// Initialize this before runApp() and override the value in ProviderScope.
final audioHandlerProvider = Provider<AudioHandler?>((ref) => null);

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;
  final Duration bufferedPosition;
  final PlaybackState? playbackState;
  final double speed;
  final DateTime? sleepTimerEndTime;

  const MediaState({
    this.mediaItem,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.playbackState,
    this.speed = 1.0,
    this.sleepTimerEndTime,
  });

  bool get isPlaying => playbackState?.playing ?? false;
  bool get isBuffering =>
      playbackState?.processingState == AudioProcessingState.buffering;
  Duration get duration => mediaItem?.duration ?? Duration.zero;

  MediaState copyWith({
    MediaItem? mediaItem,
    bool clearMediaItem = false,
    Duration? position,
    Duration? bufferedPosition,
    PlaybackState? playbackState,
    double? speed,
    DateTime? sleepTimerEndTime,
    bool clearSleepTimer = false,
  }) {
    return MediaState(
      mediaItem: clearMediaItem ? null : (mediaItem ?? this.mediaItem),
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      playbackState: playbackState ?? this.playbackState,
      speed: speed ?? this.speed,
      sleepTimerEndTime: clearSleepTimer ? null : (sleepTimerEndTime ?? this.sleepTimerEndTime),
    );
  }
}

class MediaStateNotifier extends Notifier<MediaState> {
  AudioHandler get _handler => ref.read(audioHandlerProvider)!;
  Timer? _sleepTimer;

  @override
  MediaState build() {
    _listenToHandler();
    return const MediaState();
  }

  void _listenToHandler() {
    final handler = ref.read(audioHandlerProvider);
    if (handler == null) return;

    handler.mediaItem.listen((item) {
      if (item == null) {
        state = state.copyWith(clearMediaItem: true);
      } else {
        state = state.copyWith(mediaItem: item);
      }
    });

    handler.playbackState.listen((playbackState) {
      state = state.copyWith(playbackState: playbackState);
    });

    AudioService.position.listen((position) {
      state = state.copyWith(position: position);
    });
  }

  Future<void> playAudio({
    required String url,
    required String title,
    required String author,
    String? imageUrl,
  }) async {
    String playUrl = url;
    final download = await localDb.getDownload(url);
    if (download != null && download.status == 'completed') {
      final file = File(download.localPath);
      if (await file.exists()) {
        playUrl = file.uri.toString();
      }
    }

    await _handler.customAction('playUrl', {
      'url': playUrl,
      'id': url,
      'title': title,
      'author': author,
      'imageUrl': imageUrl ?? '',
    });
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> stop() => _handler.stop();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> fastForward() => _handler.fastForward();
  Future<void> rewind() => _handler.rewind();

  Future<void> setSpeed(double speed) async {
    await _handler.customAction('setSpeed', {'speed': speed});
    state = state.copyWith(speed: speed);
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    final endTime = DateTime.now().add(duration);
    state = state.copyWith(sleepTimerEndTime: endTime);

    _sleepTimer = Timer(duration, () {
      pause();
      clearSleepTimer();
    });
  }

  void clearSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(clearSleepTimer: true);
  }
}

final mediaStateProvider = NotifierProvider<MediaStateNotifier, MediaState>(() {
  return MediaStateNotifier();
});

// Video PiP State using NotifierProvider for Riverpod 3.x compatibility
class PipVideoNotifier extends Notifier<VideoPlayerController?> {
  @override
  VideoPlayerController? build() => null;

  void setController(VideoPlayerController? controller) {
    state = controller;
  }
}

final pipVideoProvider =
    NotifierProvider<PipVideoNotifier, VideoPlayerController?>(() {
  return PipVideoNotifier();
});
