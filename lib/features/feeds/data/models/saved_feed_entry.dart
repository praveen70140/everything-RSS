import 'package:hive_ce/hive.dart';

part 'saved_feed_entry.g.dart';

@HiveType(typeId: 2)
class SavedFeedEntry extends HiveObject {
  @HiveField(0)
  int isarId =
      -1; // Keeping the name for compatibility with other parts, even though it's Hive now

  @HiveField(1)
  late String feedUrl;

  @HiveField(2)
  late String entryId; // Maps to FeedEntry.id

  @HiveField(3)
  late String title;

  @HiveField(4)
  late String subtitle;

  @HiveField(5)
  late String mediaType;

  @HiveField(6)
  String? mediaUrl;

  @HiveField(7)
  late String status; // 'archive' or 'todo'
}
