// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_media.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadedMediaAdapter extends TypeAdapter<DownloadedMedia> {
  @override
  final typeId = 4;

  @override
  DownloadedMedia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedMedia(
      url: fields[0] as String,
      localPath: fields[1] as String,
      title: fields[2] as String,
      mediaType: fields[3] as String,
      progress: fields[4] == null ? 0.0 : (fields[4] as num).toDouble(),
      status: fields[5] == null ? 'downloading' : fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedMedia obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.localPath)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.mediaType)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
