import 'package:hive_ce/hive.dart';

part 'downloaded_media.g.dart';

@HiveType(typeId: 4)
class DownloadedMedia extends HiveObject {
  @HiveField(0)
  String url;

  @HiveField(1)
  String localPath;

  @HiveField(2)
  String title;

  @HiveField(3)
  String mediaType;

  @HiveField(4)
  double progress;

  @HiveField(5)
  String status; // 'downloading', 'completed', 'failed', 'paused'

  DownloadedMedia({
    required this.url,
    required this.localPath,
    required this.title,
    required this.mediaType,
    this.progress = 0.0,
    this.status = 'downloading',
  });
}
