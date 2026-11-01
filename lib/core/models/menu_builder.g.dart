// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_builder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuBuilderAdapter extends TypeAdapter<MenuBuilder> {
  @override
  final int typeId = 3;

  @override
  MenuBuilder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuBuilder()
      ..id = fields[0] as String
      ..venueName = fields[1] as String
      ..selectedCocktailIds = (fields[2] as List).cast<String>()
      ..theme = fields[3] as String
      ..createdAt = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, MenuBuilder obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.venueName)
      ..writeByte(2)
      ..write(obj.selectedCocktailIds)
      ..writeByte(3)
      ..write(obj.theme)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuBuilderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
