import 'package:isar/isar.dart';

part 'local_feed_item.g.dart';

@collection
class LocalFeedItem {
  Id id = Isar.autoIncrement;

  late String name;
  late String url;
  
  // Optional reference to a folder ID. null means it's in the root.
  int? folderId; 
  
  int sortOrder = 0;
}
