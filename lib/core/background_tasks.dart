import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import 'database/local_db.dart';
import 'download_manager.dart';
import '../features/feeds/data/repositories/rss_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await localDb.init();
      await downloadManager.init();

      final rssService = RssService();
      final feeds = await localDb.getFeeds();

      for (final feed in feeds) {
        if (feed.autoDownload) {
          final now = TimeOfDay.now();
          // Check time if configured
          if (feed.autoDownloadTime != null &&
              feed.autoDownloadTime!.isNotEmpty) {
            final parts = feed.autoDownloadTime!.split(':');
            if (parts.length == 2) {
              final hour = int.tryParse(parts[0]) ?? 0;
              final minute = int.tryParse(parts[1]) ?? 0;

              // Very simple time check for demonstration. Real-world might need tighter window logic.
              // We will run the download if we are within the same hour
              if (now.hour != hour) {
                continue; // Skip if not the right hour
              }
            }
          }

          final fetchUrl = await localDb.getProxyUrl(feed.url);
          final entries =
              await rssService.fetchFeed(fetchUrl, forceRefresh: true);

          for (final entry in entries) {
            if (entry.mediaUrl != null && entry.mediaUrl!.isNotEmpty) {
              await downloadManager.startDownload(
                entry.mediaUrl!,
                entry.title,
                entry.mediaType.toString(),
                requireWiFi: feed.requireWiFi,
              );
            }
          }
        }
      }
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

class BackgroundTasks {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic task to check feeds every 1 hour (minimum allowed by Workmanager)
    Workmanager().registerPeriodicTask(
      "feed_auto_downloader",
      "autoDownloadFeeds",
      frequency: const Duration(hours: 1),
    );
  }
}
