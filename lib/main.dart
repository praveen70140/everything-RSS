import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'package:video_player/video_player.dart';

import 'core/theme/app_theme.dart';
import 'core/database/local_db.dart';
import 'core/media/audio_handler.dart';
import 'core/media/media_provider.dart';
import 'core/download_manager.dart';
import 'core/background_tasks.dart';
import 'features/feeds/presentation/pages/feeds_page.dart';
import 'features/media/presentation/widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Tasks
  await BackgroundTasks.init();

  // Initialize Isar Local Database
  await localDb.init();

  // Initialize Download Manager
  await downloadManager.init();

  // Initialize Audio Service
  final audioHandler = await initAudioService();

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const EverythingRSSApp(),
    ),
  );
}

class EverythingRSSApp extends StatelessWidget {
  const EverythingRSSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everything RSS',
      theme: AppTheme.darkTheme,
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipVideoController = ref.watch(pipVideoProvider);

    return PipWidget(
      onPipExited: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final controller = ref.read(pipVideoProvider);
          controller?.dispose();
          ref.read(pipVideoProvider.notifier).setController(null);
        });
      },
      pipBuilder: (context) {
        if (pipVideoController != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: AspectRatio(
                aspectRatio: pipVideoController.value.aspectRatio,
                child: VideoPlayer(pipVideoController),
              ),
            ),
          );
        }
        return const Scaffold(backgroundColor: Colors.black);
      },
      builder: (context) {
        return Scaffold(
          body: Stack(
            children: [
              const FeedsPage(),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(),
              ),
            ],
          ),
        );
      },
    );
  }
}
