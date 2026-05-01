// File: lib/data/models/food_report.dart
import 'package:hive/hive.dart';

part 'food_report.g.dart';

@HiveType(typeId: 0)
class FoodReport extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String itemName;

  @HiveField(2)
  final double quantity;

  @HiveField(3)
  final String unit;

  @HiveField(4)
  final String urgency;

  @HiveField(5)
  final double lat;

  @HiveField(6)
  final double lng;

  @HiveField(7)
  final bool isSynced;

  @HiveField(8)
  final DateTime createdAt;

  FoodReport({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.urgency,
    required this.lat,
    required this.lng,
    this.isSynced = false,
    required this.createdAt,
  });
}