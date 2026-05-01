// File: lib/data/models/camp.dart
import 'package:hive/hive.dart';

part 'camp.g.dart';

@HiveType(typeId: 2)
class FoodCamp extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String location;

  @HiveField(3)
  final String time;

  @HiveField(4)
  int mealsAvailable;

  @HiveField(5)
  final String verificationCode;

  @HiveField(6)
  final String status; // OPEN, LOW, CLOSED

  @HiveField(7)
  final String contactPhone; // Required for civilian-to-camp SMS

  FoodCamp({
    required this.id,
    required this.name,
    required this.location,
    required this.time,
    required this.mealsAvailable,
    required this.verificationCode,
    this.status = "OPEN",
    required this.contactPhone,
  });
}