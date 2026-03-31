import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:background_downloader/background_downloader.dart';

import '../../../../../core/database/local_db.dart';
import '../../../../../core/download_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/downloaded_media.dart';

class DownloadButton extends StatelessWidget {
  final String url;
  final String title;
  final String mediaType; // 'video' or 'audio'

  const DownloadButton({
    super.key,
    required this.url,
    required this.title,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<DownloadedMedia>>(
      valueListenable: localDb.getDownloadsListenable(),
      builder: (context, box, child) {
        final download = box.get(localDb.safeKey(url));

        if (download == null) {
          return IconButton(
            icon: Icon(Icons.download, color: AppColors.text),
            onPressed: () => downloadManager
                .startDownload(url, title, mediaType, requireWiFi: false),
            tooltip: 'Download',
          );
        }

        switch (download.status) {
          case 'downloading':
            return Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: download.progress > 0 ? download.progress : null,
                  color: AppColors.blue,
                ),
                IconButton(
                  icon: Icon(Icons.pause, size: 16, color: AppColors.text),
                  onPressed: () {
                    // background_downloader pause task
                    FileDownloader()
                        .taskForId(localDb.safeKey(url))
                        .then((task) {
                      if (task is DownloadTask) FileDownloader().pause(task);
                    });
                  },
                ),
              ],
            );
          case 'paused':
            return Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: download.progress,
                  color: AppColors.overlay0,
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow, size: 16, color: AppColors.text),
                  onPressed: () {
                    FileDownloader()
                        .taskForId(localDb.safeKey(url))
                        .then((task) {
                      if (task is DownloadTask) FileDownloader().resume(task);
                    });
                  },
                ),
              ],
            );
          case 'completed':
            return IconButton(
              icon: Icon(Icons.offline_pin, color: AppColors.green),
              onPressed: () {
                // Confirm delete
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Download'),
                    content: Text('Remove this downloaded file?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          downloadManager.removeDownload(url);
                          Navigator.pop(context);
                        },
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Downloaded (Tap to delete)',
            );
          case 'failed':
          default:
            return IconButton(
              icon: Icon(Icons.error_outline, color: AppColors.red),
              onPressed: () {
                downloadManager.removeDownload(url).then((_) {
                  downloadManager.startDownload(url, title, mediaType,
                      requireWiFi: false);
                });
              },
              tooltip: 'Retry Download',
            );
        }
      },
    );
  }
}
