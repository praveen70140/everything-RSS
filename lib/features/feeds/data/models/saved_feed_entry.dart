import 'package:isar/isar.dart';

part 'saved_feed_entry.g.dart';

@collection
class SavedFeedEntry {
  Id isarId = Isar.autoIncrement;

  @Index(type: IndexType.hash)
  late String feedUrl;

  @Index(unique: true, replace: true)
  late String entryId; // Maps to FeedEntry.id

  late String title;
  late String subtitle;
  late String mediaType;
  String? mediaUrl;

  @Index(type: IndexType.hash)
  late String status; // 'archive' or 'todo'
}
