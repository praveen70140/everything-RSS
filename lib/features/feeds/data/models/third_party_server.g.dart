// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'third_party_server.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThirdPartyServerAdapter extends TypeAdapter<ThirdPartyServer> {
  @override
  final typeId = 3;

  @override
  ThirdPartyServer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThirdPartyServer(
      id: fields[0] as String,
      url: fields[1] as String,
      name: fields[2] as String,
      supportedDomains:
          fields[3] == null ? const [] : (fields[3] as List).cast<String>(),
      serverType: fields[4] == null ? 'ytdlp' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ThirdPartyServer obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.supportedDomains)
      ..writeByte(4)
      ..write(obj.serverType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThirdPartyServerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
