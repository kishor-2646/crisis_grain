// File: lib/data/models/food_need.dart
import 'package:hive/hive.dart';

part 'food_need.g.dart';

@HiveType(typeId: 1) // Unique ID for Hive
class FoodNeed extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int peopleCount;

  @HiveField(2)
  final String locationArea;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final bool isSentViaSMS;

  FoodNeed({
    required this.id,
    required this.peopleCount,
    required this.locationArea,
    required this.createdAt,
    this.isSentViaSMS = false,
  });
}