// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StopItemAdapter extends TypeAdapter<StopItem> {
  @override
  final int typeId = 1;

  @override
  StopItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StopItem(
      name: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StopItem obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
