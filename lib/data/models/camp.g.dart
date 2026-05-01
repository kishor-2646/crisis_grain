// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camp.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodCampAdapter extends TypeAdapter<FoodCamp> {
  @override
  final int typeId = 2;

  @override
  FoodCamp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodCamp(
      id: fields[0] as String,
      name: fields[1] as String,
      location: fields[2] as String,
      time: fields[3] as String,
      mealsAvailable: fields[4] as int,
      verificationCode: fields[5] as String,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FoodCamp obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.mealsAvailable)
      ..writeByte(5)
      ..write(obj.verificationCode)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodCampAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
