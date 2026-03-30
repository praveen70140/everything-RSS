// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_feed_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalFeedItemAdapter extends TypeAdapter<LocalFeedItem> {
  @override
  final typeId = 1;

  @override
  LocalFeedItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalFeedItem()
      ..id = (fields[0] as num).toInt()
      ..name = fields[1] as String
      ..url = fields[2] as String
      ..folderId = (fields[3] as num?)?.toInt()
      ..sortOrder = (fields[4] as num).toInt()
      ..autoDownload = fields[5] == null ? false : fields[5] as bool
      ..requireWiFi = fields[6] == null ? true : fields[6] as bool
      ..autoDownloadTime = fields[7] as String?;
  }

  @override
  void write(BinaryWriter writer, LocalFeedItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.folderId)
      ..writeByte(4)
      ..write(obj.sortOrder)
      ..writeByte(5)
      ..write(obj.autoDownload)
      ..writeByte(6)
      ..write(obj.requireWiFi)
      ..writeByte(7)
      ..write(obj.autoDownloadTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalFeedItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
