// File: lib/core/constants.dart
import 'package:flutter/material.dart';
import 'theme.dart'; // Import theme to use the single AppColors class

enum UserRole { civilian, ngo, volunteer }

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

class AppConstants {
  static const String boxFoodNeeds = "foodNeeds";
  static const String boxFoodCamps = "foodCamps";
  static const String boxFoodReports = "foodReports";
}