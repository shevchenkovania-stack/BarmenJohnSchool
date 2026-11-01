// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_recipe.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomRecipeAdapter extends TypeAdapter<CustomRecipe> {
  @override
  final int typeId = 2;

  @override
  CustomRecipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomRecipe(
      id: fields[0] as String,
      name: fields[1] as String,
      ingredients: (fields[2] as List).cast<String>(),
      measures: (fields[3] as List).cast<String>(),
      instructions: fields[4] as String,
      glass: fields[5] as String,
      createdAt: fields[6] as DateTime,
      sellingPrice: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CustomRecipe obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ingredients)
      ..writeByte(3)
      ..write(obj.measures)
      ..writeByte(4)
      ..write(obj.instructions)
      ..writeByte(5)
      ..write(obj.glass)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.sellingPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomRecipeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
