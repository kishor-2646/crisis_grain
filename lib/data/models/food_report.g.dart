// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodReportAdapter extends TypeAdapter<FoodReport> {
  @override
  final int typeId = 0;

  @override
  FoodReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodReport(
      id: fields[0] as String,
      itemName: fields[1] as String,
      quantity: fields[2] as double,
      unit: fields[3] as String,
      urgency: fields[4] as String,
      lat: fields[5] as double,
      lng: fields[6] as double,
      isSynced: fields[7] as bool,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodReport obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.urgency)
      ..writeByte(5)
      ..write(obj.lat)
      ..writeByte(6)
      ..write(obj.lng)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
