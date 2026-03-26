import 'package:isar/isar.dart';

part 'local_feed_folder.g.dart';

@collection
class LocalFeedFolder {
  Id id = Isar.autoIncrement;

  late String name;
  bool isExpanded = false;
  int sortOrder = 0;
}
