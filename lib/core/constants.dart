// File: lib/core/constants.dart
import 'package:flutter/material.dart';

/// Defines the roles for the system
enum UserRole { civilian, ngo, volunteer }

class AppColors {
  static const primary = Color(0xFF1B5E20); // Deep Humanitarian Green
  static const secondary = Color(0xFF2E7D32);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFFFA000);
  static const success = Color(0xFF388E3C);
  static const accent = Color(0xFF1976D2); // Trust Blue
}

class AppUrgency {
  static const String surplus = "SURPLUS";
  static const String low = "LOW";
  static const String critical = "CRITICAL";

  static Color getColor(String level) {
    switch (level) {
      case surplus: return AppColors.success;
      case low: return AppColors.warning;
      case critical: return AppColors.error;
      default: return Colors.grey;
    }
  }
}

/// Hive Box names
class AppConstants {
  static const String boxFoodNeeds = "foodNeeds";
  static const String boxFoodCamps = "foodCamps";
  static const String boxFoodReports = "foodReports";
}