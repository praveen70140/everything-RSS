// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_feed_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedFeedEntryAdapter extends TypeAdapter<SavedFeedEntry> {
  @override
  final typeId = 2;

  @override
  SavedFeedEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedFeedEntry()
      ..isarId = (fields[0] as num).toInt()
      ..feedUrl = fields[1] as String
      ..entryId = fields[2] as String
      ..title = fields[3] as String
      ..subtitle = fields[4] as String
      ..mediaType = fields[5] as String
      ..mediaUrl = fields[6] as String?
      ..status = fields[7] as String;
  }

  @override
  void write(BinaryWriter writer, SavedFeedEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.isarId)
      ..writeByte(1)
      ..write(obj.feedUrl)
      ..writeByte(2)
      ..write(obj.entryId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.subtitle)
      ..writeByte(5)
      ..write(obj.mediaType)
      ..writeByte(6)
      ..write(obj.mediaUrl)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedFeedEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
