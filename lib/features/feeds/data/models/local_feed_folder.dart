import 'package:hive_ce/hive.dart';

part 'local_feed_folder.g.dart';

@HiveType(typeId: 0)
class LocalFeedFolder extends HiveObject {
  @HiveField(0)
  int id = -1;

  @HiveField(1)
  late String name;

  @HiveField(2)
  bool isExpanded = false;

  @HiveField(3)
  int sortOrder = 0;
}
