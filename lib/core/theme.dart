// File: lib/core/theme.dart
import 'package:flutter/material.dart';

/// Single source of truth for the app's color palette.
class AppColors {
  // Softened Humanitarian Red (Muted from E53935 to CF4542)
  static const Color primary = Color(0xFFCF4542);
  static const Color accent = Color(0xFF00B0FF);
  static const Color warning = Color(0xFFFFC107);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color background = Color(0xFF0F0F0F);

  // Glassmorphism Hex Constants (prevents "const" errors)
  static const Color glassWhite = Color(0x1FFFFFFF); // 12% Opacity White
  static const Color glassStroke = Color(0x33FFFFFF); // 20% Opacity White
}

class AppStyles {
  /// Generates a glassmorphism decoration.
  /// Named 'glass' to match your screen implementations.
  static BoxDecoration glass({double radius = 24}) {
    return BoxDecoration(
      color: AppColors.glassWhite,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassStroke, width: 1.5),
    );
  }
}