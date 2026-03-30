import 'package:hive_ce/hive.dart';

part 'local_feed_item.g.dart';

@HiveType(typeId: 1)
class LocalFeedItem extends HiveObject {
  @HiveField(0)
  int id = -1;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String url;

  // Optional reference to a folder ID. null means it's in the root.
  @HiveField(3)
  int? folderId;

  @HiveField(4)
  int sortOrder = 0;

  @HiveField(5, defaultValue: false)
  bool autoDownload = false;

  @HiveField(6, defaultValue: true)
  bool requireWiFi = true;

  @HiveField(7, defaultValue: null)
  String? autoDownloadTime;
}
