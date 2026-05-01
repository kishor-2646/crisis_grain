// File: lib/data/models/food_need.dart
import 'package:hive/hive.dart';

part 'food_need.g.dart';

@HiveType(typeId: 1)
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

  @HiveField(5)
  final bool isSynced;

  @HiveField(6)
  final String phoneNumber; // Required for targeted SMS logic

  FoodNeed({
    required this.id,
    required this.peopleCount,
    required this.locationArea,
    required this.createdAt,
    this.isSentViaSMS = false,
    this.isSynced = false,
    required this.phoneNumber,
  });
}