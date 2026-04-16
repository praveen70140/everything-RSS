import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

Future<AudioHandler> initAudioService() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.speech());

  return await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.everything_rss.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  AppAudioHandler() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;

      final state = {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: state,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });

    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        pause();
        _player.seek(Duration.zero);
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
    return super.stop();
  }

  @override
  Future<void> fastForward() async {
    final newPos = _player.position + const Duration(seconds: 30);
    await seek(newPos);
  }

  @override
  Future<void> rewind() async {
    final newPos = _player.position - const Duration(seconds: 10);
    await seek(newPos > Duration.zero ? newPos : Duration.zero);
  }

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (name == 'playUrl') {
      final url = extras?['url'] as String;
      final id = extras?['id'] as String? ?? url;
      final title = extras?['title'] as String;
      final author = extras?['author'] as String;
      final imageUrl = extras?['imageUrl'] as String;

      final item = MediaItem(
        id: id,
        album: author,
        title: title,
        artUri: (imageUrl.isNotEmpty) ? Uri.parse(imageUrl) : null,
      );

      mediaItem.add(item);

      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.play();
    } else if (name == 'setSpeed') {
      final speed = extras?['speed'] as double;
      await _player.setSpeed(speed);
    } else if (name == 'getSpeed') {
      return _player.speed;
    }
  }
}
