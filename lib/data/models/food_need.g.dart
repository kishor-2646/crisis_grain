// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_need.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodNeedAdapter extends TypeAdapter<FoodNeed> {
  @override
  final int typeId = 1;

  @override
  FoodNeed read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Using null-safe casting with default values to handle schema migrations
    return FoodNeed(
      id: fields[0] as String,
      peopleCount: fields[1] as int,
      locationArea: fields[2] as String,
      createdAt: fields[3] as DateTime,
      isSentViaSMS: (fields[4] as bool?) ?? false,
      isSynced: (fields[5] as bool?) ?? false,
      phoneNumber: (fields[6] as String?) ?? "N/A",
    );
  }

  @override
  void write(BinaryWriter writer, FoodNeed obj) {
    writer
      ..writeByte(7) // Correctly writing 7 fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.peopleCount)
      ..writeByte(2)
      ..write(obj.locationArea)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isSentViaSMS)
      ..writeByte(5)
      ..write(obj.isSynced)
      ..writeByte(6)
      ..write(obj.phoneNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FoodNeedAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}