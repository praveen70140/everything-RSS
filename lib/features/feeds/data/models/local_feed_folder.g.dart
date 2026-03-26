// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_feed_folder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalFeedFolderAdapter extends TypeAdapter<LocalFeedFolder> {
  @override
  final typeId = 0;

  @override
  LocalFeedFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalFeedFolder()
      ..id = (fields[0] as num).toInt()
      ..name = fields[1] as String
      ..isExpanded = fields[2] as bool
      ..sortOrder = (fields[3] as num).toInt();
  }

  @override
  void write(BinaryWriter writer, LocalFeedFolder obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isExpanded)
      ..writeByte(3)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalFeedFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
