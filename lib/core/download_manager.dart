import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../features/feeds/data/models/downloaded_media.dart';
import 'database/local_db.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    FileDownloader().configureNotificationForGroup(
      FileDownloader.defaultGroup,
      running: const TaskNotification(
          'Downloading {filename}', 'progress: {progress}'),
      complete: const TaskNotification('Download complete', '{filename}'),
      error: const TaskNotification('Download failed', '{filename}'),
      paused: const TaskNotification('Download paused', '{filename}'),
      progressBar: true,
    );

    await FileDownloader().configure(globalConfig: [
      (Config.runInForeground, Config.always),
    ]);

    FileDownloader().updates.listen((update) async {
      if (update is TaskStatusUpdate) {
        await _handleStatusUpdate(update);
      } else if (update is TaskProgressUpdate) {
        await _handleProgressUpdate(update);
      }
    });

    _initialized = true;
  }

  Future<void> _handleStatusUpdate(TaskStatusUpdate update) async {
    final url = update.task.url;
    final download = await localDb.getDownload(url);
    if (download != null) {
      if (update.status == TaskStatus.complete) {
        download.status = 'completed';
        download.progress = 1.0;
        await download.save();
      } else if (update.status == TaskStatus.failed ||
          update.status == TaskStatus.canceled) {
        download.status = 'failed';
        await download.save();
      } else if (update.status == TaskStatus.paused) {
        download.status = 'paused';
        await download.save();
      }
    }
  }

  Future<void> _handleProgressUpdate(TaskProgressUpdate update) async {
    final url = update.task.url;
    final download = await localDb.getDownload(url);
    if (download != null) {
      if (update.progress >= 0.0 && update.progress <= 1.0) {
        download.progress = update.progress;
        download.status = 'downloading';
        await download.save();
      }
    }
  }

  Future<void> startDownload(String url, String title, String mediaType) async {
    if (url.isEmpty) return;

    final existing = await localDb.getDownload(url);
    if (existing != null && existing.status == 'completed') {
      return; // Already downloaded
    }

    // Extract extension
    final uri = Uri.parse(url);
    String ext = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last.split('.').last
        : 'mp4';
    if (!['mp4', 'mp3', 'm4a', 'wav'].contains(ext.toLowerCase())) {
      ext = mediaType == 'video' ? 'mp4' : 'mp3';
    }

    final filename = '${const Uuid().v4()}.$ext';
    final task = DownloadTask(
      url: url,
      filename: filename,
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: true,
    );

    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/$filename';

    final media = existing ??
        DownloadedMedia(
          url: url,
          localPath: localPath,
          title: title,
          mediaType: mediaType,
          progress: 0.0,
          status: 'downloading',
        );
    await localDb.saveDownload(media);

    await FileDownloader().enqueue(task);
  }

  Future<void> removeDownload(String url) async {
    final media = await localDb.getDownload(url);
    if (media != null) {
      try {
        final file = File(media.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file delete errors
      }
      await localDb.deleteDownload(url);
    }
  }
}

final downloadManager = DownloadManager();
