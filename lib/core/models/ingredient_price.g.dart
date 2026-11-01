// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_price.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientPriceAdapter extends TypeAdapter<IngredientPrice> {
  @override
  final int typeId = 4;

  @override
  IngredientPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientPrice(
      name: fields[0] as String,
      bottlePrice: fields[1] as double,
      bottleSizeMl: fields[2] as double,
      currency: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientPrice obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.bottlePrice)
      ..writeByte(2)
      ..write(obj.bottleSizeMl)
      ..writeByte(3)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
